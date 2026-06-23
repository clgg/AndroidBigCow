import { createServer } from 'node:http';
import { createHash, createHmac, timingSafeEqual } from 'node:crypto';
import { execFile } from 'node:child_process';
import { readFile, writeFile, mkdir, stat } from 'node:fs/promises';
import { existsSync } from 'node:fs';
import { basename, extname, join, resolve } from 'node:path';
import { promisify } from 'node:util';
import { fileURLToPath } from 'node:url';
import WebSocket from 'ws';

const __dirname = fileURLToPath(new URL('.', import.meta.url));
const rootDir = resolve(__dirname, '..');
const dataDir = join(rootDir, 'data');
const publicDir = join(rootDir, 'public');
const audioDir = process.env.AUDIO_DIR || join(dataDir, 'audio');
const questionsPath = join(dataDir, 'questions.json');
const questionsDbPath = join(dataDir, 'questions.db');
const catalogPath = join(dataDir, 'tech-catalog.json');
const progressPath = join(dataDir, 'progress-sync.json');
const ttsConfigPath = join(dataDir, 'tts-config.json');
const execFileAsync = promisify(execFile);

const port = Number(process.env.PORT || 8080);
const adminUsername = process.env.ADMIN_USERNAME || 'admin';
const adminPassword = process.env.ADMIN_PASSWORD || 'change-me-now';
const publicBaseUrl = (process.env.PUBLIC_BASE_URL || `http://localhost:${port}`).replace(/\/+$/, '');
const xfyunAppId = process.env.XFYUN_APP_ID || '';
const xfyunApiKey = process.env.XFYUN_API_KEY || '';
const xfyunApiSecret = process.env.XFYUN_API_SECRET || '';
const xfyunVoice = process.env.XFYUN_TTS_VOICE || 'xiaoyan';
const xfyunSpeed = Number(process.env.XFYUN_TTS_SPEED || 50);
const xfyunPitch = Number(process.env.XFYUN_TTS_PITCH || 50);
const xfyunVolume = Number(process.env.XFYUN_TTS_VOLUME || 50);
const audioJobs = new Map();

const mimeTypes = {
  '.html': 'text/html; charset=utf-8',
  '.css': 'text/css; charset=utf-8',
  '.js': 'application/javascript; charset=utf-8',
  '.json': 'application/json; charset=utf-8',
  '.png': 'image/png',
  '.svg': 'image/svg+xml',
};

await ensureDataFiles();

createServer(async (request, response) => {
  try {
    if (request.method === 'OPTIONS') {
      return sendNoContent(response);
    }

    const url = new URL(request.url ?? '/', `http://${request.headers.host}`);
    const pathname = normalizePath(url.pathname);
    const adminRoute = isAdminRoute(pathname);

    if (adminRoute && !isAdminAuthorized(request)) {
      return sendUnauthorized(response);
    }

    if (pathname === '/') {
      return redirect(response, '/admin');
    }
    if (pathname === '/admin') {
      return sendStatic(response, join(publicDir, 'admin.html'));
    }
    if (pathname.startsWith('/admin/')) {
      return sendStatic(response, join(publicDir, pathname.replace('/admin/', '')));
    }
    if (pathname.startsWith('/audio/')) {
      return sendAudio(request, response, pathname.replace('/audio/', ''));
    }

    if (pathname === '/api/health' && request.method === 'GET') {
      return sendJson(response, { ok: true, service: 'interview-bank-server' });
    }
    if (pathname === '/api/auth/register' && request.method === 'POST') {
      const body = await readBody(request);
      return sendJson(response, demoAuthResponse(body, 'register'));
    }
    if (pathname === '/api/auth/login' && request.method === 'POST') {
      const body = await readBody(request);
      return sendJson(response, demoAuthResponse(body, 'login'));
    }
    if (pathname === '/api/tech/categories' && request.method === 'GET') {
      return sendJson(response, await readJson(catalogPath, []));
    }
    if (pathname === '/api/questions' && request.method === 'GET') {
      return sendJson(response, await queryQuestions(url.searchParams));
    }
    if (pathname === '/api/questions/latest' && request.method === 'GET') {
      return sendJson(response, await syncQuestions(url.searchParams));
    }
    if (pathname === '/api/questions/sync' && request.method === 'GET') {
      return sendJson(response, await syncQuestions(url.searchParams));
    }
    if (pathname === '/api/progress/sync' && request.method === 'POST') {
      const body = await readBody(request);
      const saved = await appendProgress(body);
      return sendJson(response, saved);
    }
    if (pathname === '/api/admin/questions' && request.method === 'GET') {
      return sendJson(response, await queryQuestions(url.searchParams));
    }
    if (pathname === '/api/admin/questions' && request.method === 'POST') {
      const body = await readBody(request);
      const saved = await upsertQuestion(body);
      return sendJson(response, saved);
    }
    if (pathname === '/api/admin/questions/import' && request.method === 'POST') {
      const body = await readBody(request);
      return sendJson(response, await importQuestions(body));
    }
    if (pathname === '/api/admin/questions/template' && request.method === 'GET') {
      return sendJson(response, questionImportTemplate());
    }
    if (pathname === '/api/admin/audio/generate-standard-answers' && request.method === 'POST') {
      const body = await readBody(request);
      return sendJson(response, await startStandardAnswerAudioJob(body), 202);
    }
    if (pathname.startsWith('/api/admin/audio/jobs/') && request.method === 'GET') {
      const id = decodeURIComponent(pathname.replace('/api/admin/audio/jobs/', ''));
      const job = audioJobs.get(id);
      if (!job) {
        return sendJson(response, { error: 'job not found' }, 404);
      }
      return sendJson(response, publicAudioJob(job));
    }
    if (pathname === '/api/admin/tts-config' && request.method === 'GET') {
      return sendJson(response, await readTtsConfig());
    }
    if (pathname === '/api/admin/tts-config' && request.method === 'PUT') {
      const body = await readBody(request);
      return sendJson(response, await saveTtsConfig(body));
    }
    if (pathname.startsWith('/api/admin/questions/') && request.method === 'DELETE') {
      const id = decodeURIComponent(pathname.replace('/api/admin/questions/', ''));
      return sendJson(response, await deleteQuestion(id));
    }
    if (pathname === '/api/admin/tech-catalog' && request.method === 'GET') {
      return sendJson(response, await readJson(catalogPath, []));
    }
    if (pathname === '/api/admin/tech-catalog' && request.method === 'PUT') {
      const body = await readBody(request);
      if (!Array.isArray(body)) {
        return sendJson(response, { error: 'tech catalog must be an array' }, 400);
      }
      await writeJson(catalogPath, body);
      return sendJson(response, body);
    }
    if (pathname === '/api/admin/progress' && request.method === 'GET') {
      return sendJson(response, await readJson(progressPath, []));
    }

    return sendJson(response, { error: 'not found' }, 404);
  } catch (error) {
    console.error(error);
    return sendJson(response, { error: error.message || 'internal error' }, 500);
  }
}).listen(port, () => {
  console.log(`Interview bank server listening on http://0.0.0.0:${port}`);
  if (adminPassword === 'change-me-now') {
    console.warn('ADMIN_PASSWORD is using the default value. Set ADMIN_PASSWORD before public deployment.');
  }
});

function normalizePath(pathname) {
  return pathname.replace(/\/+$/, '') || '/';
}

function isAdminRoute(pathname) {
  return pathname === '/admin' ||
    pathname.startsWith('/admin/') ||
    pathname === '/api/admin' ||
    pathname.startsWith('/api/admin/');
}

function isAdminAuthorized(request) {
  const authorization = request.headers.authorization || '';
  if (!authorization.startsWith('Basic ')) {
    return false;
  }

  try {
    const decoded = Buffer.from(authorization.slice(6), 'base64').toString('utf8');
    const separatorIndex = decoded.indexOf(':');
    if (separatorIndex < 0) {
      return false;
    }
    const username = decoded.slice(0, separatorIndex);
    const password = decoded.slice(separatorIndex + 1);
    return secureEqual(username, adminUsername) && secureEqual(password, adminPassword);
  } catch (_) {
    return false;
  }
}

function secureEqual(value, expected) {
  const valueBuffer = Buffer.from(String(value));
  const expectedBuffer = Buffer.from(String(expected));
  if (valueBuffer.length !== expectedBuffer.length) {
    return false;
  }
  return timingSafeEqual(valueBuffer, expectedBuffer);
}

async function ensureDataFiles() {
  await mkdir(dataDir, { recursive: true });
  await mkdir(audioDir, { recursive: true });
  if (!existsSync(questionsPath)) {
    await writeJson(questionsPath, []);
  }
  if (!existsSync(catalogPath)) {
    await writeJson(catalogPath, []);
  }
  if (!existsSync(progressPath)) {
    await writeJson(progressPath, []);
  }
  if (!existsSync(ttsConfigPath)) {
    await writeJson(ttsConfigPath, {});
  }
  await ensureQuestionDatabase();
}

async function readQuestions() {
  return queryQuestions(new URLSearchParams());
}

async function ensureQuestionDatabase() {
  await runSql(`
    PRAGMA journal_mode = DELETE;
    CREATE TABLE IF NOT EXISTS questions (
      id TEXT PRIMARY KEY,
      tech_category TEXT NOT NULL,
      tech_language TEXT NOT NULL,
      module TEXT NOT NULL,
      title TEXT NOT NULL,
      review_status TEXT NOT NULL,
      tags_json TEXT NOT NULL DEFAULT '[]',
      checkpoints_json TEXT NOT NULL DEFAULT '[]',
      answer_points_json TEXT NOT NULL DEFAULT '[]',
      follow_ups_json TEXT NOT NULL DEFAULT '[]',
      mistakes_json TEXT NOT NULL DEFAULT '[]',
      standard_answer TEXT NOT NULL DEFAULT '',
      standard_answer_audio_url TEXT,
      version INTEGER NOT NULL DEFAULT 1,
      updated_at TEXT NOT NULL,
      deleted_at TEXT
    );
    CREATE TABLE IF NOT EXISTS audio_assets (
      id TEXT PRIMARY KEY,
      text_hash TEXT NOT NULL,
      text TEXT NOT NULL,
      voice TEXT NOT NULL,
      speed INTEGER NOT NULL,
      pitch INTEGER NOT NULL,
      volume INTEGER NOT NULL,
      format TEXT NOT NULL,
      file_path TEXT NOT NULL,
      url TEXT NOT NULL,
      status TEXT NOT NULL,
      created_at TEXT NOT NULL,
      updated_at TEXT NOT NULL,
      UNIQUE(text_hash, voice, speed, pitch, volume, format)
    );
    CREATE INDEX IF NOT EXISTS idx_questions_stack ON questions(tech_category, tech_language, deleted_at);
    CREATE INDEX IF NOT EXISTS idx_questions_sync ON questions(tech_category, tech_language, version);
    CREATE INDEX IF NOT EXISTS idx_questions_module ON questions(tech_category, tech_language, module);
  `);
  await ensureColumn('questions', 'standard_answer_audio_url', 'TEXT');

  const row = await getSql('SELECT COUNT(*) AS count FROM questions;');
  if (Number(row?.count || 0) > 0) {
    return;
  }

  const seedQuestions = await readJson(questionsPath, []);
  if (seedQuestions.length === 0) {
    return;
  }
  await importQuestions({ questions: seedQuestions });
}

async function queryQuestions(searchParams) {
  const includeDeleted = searchParams.get('includeDeleted') === 'true';
  const category = searchParams.get('category');
  const language = searchParams.get('language');
  const module = searchParams.get('module');
  const query = (searchParams.get('query') || '').trim().toLowerCase();
  const page = Math.max(1, Number(searchParams.get('page') || 1));
  const pageSize = Math.min(200, Math.max(1, Number(searchParams.get('pageSize') || searchParams.get('limit') || 200)));
  const offset = Math.max(0, Number(searchParams.get('offset') || (page - 1) * pageSize));
  const paginate = searchParams.has('page') || searchParams.has('pageSize') || searchParams.has('limit') || searchParams.has('offset');

  const where = [];
  if (!includeDeleted) {
    where.push('deleted_at IS NULL');
  }
  if (category) {
    where.push(`tech_category = ${sqlString(category)}`);
  }
  if (language) {
    where.push(`tech_language = ${sqlString(language)}`);
  }
  if (module) {
    where.push(`module = ${sqlString(module)}`);
  }
  if (query) {
    const like = sqlLike(query);
    where.push(`lower(module || ' ' || title || ' ' || tags_json || ' ' || checkpoints_json || ' ' || answer_points_json || ' ' || follow_ups_json || ' ' || mistakes_json || ' ' || standard_answer) LIKE ${like}`);
  }

  const whereSql = where.length > 0 ? `WHERE ${where.join(' AND ')}` : '';
  const limitSql = paginate ? `LIMIT ${pageSize} OFFSET ${offset}` : '';
  const rows = await allSql(`
    SELECT * FROM questions
    ${whereSql}
    ORDER BY module COLLATE NOCASE, updated_at DESC, id
    ${limitSql};
  `);
  return rows.map(rowToQuestion);
}

async function syncQuestions(searchParams) {
  const category = searchParams.get('category');
  const language = searchParams.get('language');
  const sinceVersion = Number(searchParams.get('sinceVersion') || searchParams.get('afterVersion') || 0);
  const limit = Math.min(200, Math.max(1, Number(searchParams.get('limit') || searchParams.get('pageSize') || 100)));

  const where = [`version > ${Number.isFinite(sinceVersion) ? sinceVersion : 0}`];
  if (category) {
    where.push(`tech_category = ${sqlString(category)}`);
  }
  if (language) {
    where.push(`tech_language = ${sqlString(language)}`);
  }

  const rows = await allSql(`
    SELECT * FROM questions
    WHERE ${where.join(' AND ')}
    ORDER BY version ASC, id ASC
    LIMIT ${limit + 1};
  `);
  const visibleRows = rows.slice(0, limit);
  const latest = await latestVersion();
  const nextAfterVersion = visibleRows.length > 0
    ? Math.max(...visibleRows.map(row => Number(row.version || sinceVersion)))
    : sinceVersion;

  return {
    sinceVersion,
    latestVersion: latest,
    nextAfterVersion,
    hasMore: rows.length > limit,
    questions: visibleRows
      .filter(row => !row.deleted_at)
      .map(rowToQuestion),
    deletedIds: visibleRows
      .filter(row => row.deleted_at)
      .map(row => row.id),
  };
}

async function upsertQuestion(body) {
  const question = normalizeQuestion(body);
  const version = await nextVersion();
  const nextQuestion = {
    ...question,
    version,
    updatedAt: new Date().toISOString(),
  };
  await upsertQuestionRow(nextQuestion);
  return nextQuestion;
}

async function importQuestions(body, options = {}) {
  const importedQuestions = Array.isArray(body) ? body : body.questions;
  if (!Array.isArray(importedQuestions)) {
    throw new Error('import payload must be an array or { "questions": [...] }');
  }

  const replaceMode = !Array.isArray(body) &&
    (body.replace === true || body.mode === 'replace');
  const normalizedQuestions = importedQuestions.map(normalizeQuestion);
  const replaceScopes = replaceMode
    ? normalizeReplaceScopes(body.scopes, normalizedQuestions)
    : [];
  const now = new Date().toISOString();
  let created = 0;
  let updated = 0;
  let version = await latestVersion();

  for (const question of normalizedQuestions) {
    const exists = await getSql(`SELECT id FROM questions WHERE id = ${sqlString(question.id)};`);
    version += 1;
    const nextQuestion = {
      ...question,
      version: options.preserveVersions ? Number(question.version || 1) : version,
      updatedAt: now,
    };
    await upsertQuestionRow(nextQuestion);
    if (exists) {
      updated += 1;
    } else {
      created += 1;
    }
  }

  const deleted = replaceMode
    ? await deleteQuestionsMissingFromImport(normalizedQuestions, replaceScopes, now, version)
    : 0;

  return {
    ok: true,
    created,
    updated,
    deleted,
    total: Number((await getSql('SELECT COUNT(*) AS count FROM questions WHERE deleted_at IS NULL;'))?.count || 0),
  };
}

function normalizeReplaceScopes(scopes, questions) {
  const sourceScopes = Array.isArray(scopes) && scopes.length > 0
    ? scopes
    : questions.map((question) => ({
      techCategory: question.techCategory,
      techLanguage: question.techLanguage,
    }));
  const seen = new Set();
  const normalized = [];
  for (const scope of sourceScopes) {
    const techCategory = String(scope.techCategory || scope.category || '').trim();
    const techLanguage = String(scope.techLanguage || scope.language || '').trim();
    if (!techCategory || !techLanguage) {
      throw new Error('replace scopes require techCategory and techLanguage');
    }
    const key = `${techCategory}\n${techLanguage}`;
    if (seen.has(key)) {
      continue;
    }
    seen.add(key);
    normalized.push({ techCategory, techLanguage });
  }
  return normalized;
}

async function deleteQuestionsMissingFromImport(questions, scopes, now, currentVersion) {
  if (scopes.length === 0) {
    return 0;
  }

  const importedIds = new Set(questions.map((question) => question.id));
  let version = currentVersion;
  let deleted = 0;

  for (const scope of scopes) {
    const rows = await allSql(`
      SELECT id FROM questions
      WHERE tech_category = ${sqlString(scope.techCategory)}
        AND tech_language = ${sqlString(scope.techLanguage)}
        AND deleted_at IS NULL;
    `);
    for (const row of rows) {
      if (importedIds.has(row.id)) {
        continue;
      }
      version += 1;
      await runSql(`
        UPDATE questions
        SET deleted_at = ${sqlString(now)},
            version = ${version},
            updated_at = ${sqlString(now)}
        WHERE id = ${sqlString(row.id)} AND deleted_at IS NULL;
      `);
      deleted += 1;
    }
  }

  return deleted;
}

async function deleteQuestion(id) {
  const version = await nextVersion();
  const rows = await allSql(`
    UPDATE questions
    SET deleted_at = ${sqlString(new Date().toISOString())},
        version = ${version},
        updated_at = ${sqlString(new Date().toISOString())}
    WHERE id = ${sqlString(id)} AND deleted_at IS NULL;
    SELECT changes() AS changes;
  `);
  return { deleted: Number(rows[0]?.changes || 0), id };
}

async function startStandardAnswerAudioJob(body) {
  const ttsConfig = await readTtsConfig({ includeSecrets: true });
  assertTtsConfigured(ttsConfig);
  const params = new URLSearchParams();
  if (body.category) {
    params.set('category', body.category);
  }
  if (body.language) {
    params.set('language', body.language);
  }
  if (body.query) {
    params.set('query', body.query);
  }
  const questionIds = Array.isArray(body.questionIds)
    ? new Set(body.questionIds.map(String))
    : null;
  const maxCount = Math.min(500, Math.max(1, Number(body.limit || 500)));
  const questions = (await queryQuestions(params))
    .filter((question) => !questionIds || questionIds.has(question.id))
    .filter((question) => question.standardAnswer?.trim())
    .slice(0, maxCount);

  const job = {
    id: `audio-${Date.now().toString(36)}-${Math.random().toString(36).slice(2, 8)}`,
    status: 'running',
    total: questions.length,
    processed: 0,
    created: 0,
    reused: 0,
    updated: 0,
    skipped: 0,
    failures: [],
    currentQuestion: null,
    startedAt: new Date().toISOString(),
    finishedAt: null,
  };
  audioJobs.set(job.id, job);
  trimAudioJobs();
  runStandardAnswerAudioJob(job, questions, ttsConfig).catch((error) => {
    job.status = 'failed';
    job.finishedAt = new Date().toISOString();
    job.failures.push({
      id: '',
      title: '任务异常',
      error: error.message || 'job failed',
    });
  });
  return publicAudioJob(job);
}

async function runStandardAnswerAudioJob(job, questions, ttsConfig) {
  let version = await latestVersion();

  for (const question of questions) {
    job.currentQuestion = {
      id: question.id,
      title: question.title,
    };
    try {
      const result = await ensureStandardAnswerAudio(question.standardAnswer, ttsConfig);
      if (result.created) {
        job.created += 1;
      } else {
        job.reused += 1;
      }
      if (question.standardAnswerAudioUrl !== result.url) {
        version += 1;
        await runSql(`
          UPDATE questions
          SET standard_answer_audio_url = ${sqlString(result.url)},
              version = ${version},
              updated_at = ${sqlString(new Date().toISOString())}
          WHERE id = ${sqlString(question.id)} AND deleted_at IS NULL;
        `);
        job.updated += 1;
      }
    } catch (error) {
      job.skipped += 1;
      job.failures.push({
        id: question.id,
        title: question.title,
        error: error.message || 'generate failed',
      });
    } finally {
      job.processed += 1;
    }
  }

  job.currentQuestion = null;
  job.status = job.failures.length === 0 ? 'completed' : 'completed_with_errors';
  job.finishedAt = new Date().toISOString();
}

function publicAudioJob(job) {
  return {
    id: job.id,
    ok: job.status === 'completed' || job.status === 'running',
    status: job.status,
    total: job.total,
    processed: job.processed,
    percent: job.total === 0 ? 100 : Math.round((job.processed / job.total) * 100),
    created: job.created,
    reused: job.reused,
    updated: job.updated,
    skipped: job.skipped,
    currentQuestion: job.currentQuestion,
    failures: job.failures.slice(-20),
    startedAt: job.startedAt,
    finishedAt: job.finishedAt,
  };
}

function trimAudioJobs() {
  const jobs = [...audioJobs.values()]
    .sort((a, b) => String(a.startedAt).localeCompare(String(b.startedAt)));
  while (jobs.length > 20) {
    const job = jobs.shift();
    if (job && job.status !== 'running') {
      audioJobs.delete(job.id);
    }
  }
}

async function ensureStandardAnswerAudio(text, ttsConfig) {
  const normalizedText = normalizeTtsText(text);
  const byteLength = Buffer.byteLength(normalizedText, 'utf8');
  if (byteLength === 0) {
    throw new Error('standard answer is empty');
  }
  if (byteLength >= 8000) {
    throw new Error(`standard answer is too long for one TTS call: ${byteLength} bytes`);
  }

  const textHash = sha256(normalizedText);
  const format = 'mp3';
  const assetId = sha256([
    textHash,
    ttsConfig.voice,
    ttsConfig.speed,
    ttsConfig.pitch,
    ttsConfig.volume,
    format,
  ].join('|'));
  const existing = await getSql(`
    SELECT * FROM audio_assets
    WHERE text_hash = ${sqlString(textHash)}
      AND voice = ${sqlString(ttsConfig.voice)}
      AND speed = ${ttsConfig.speed}
      AND pitch = ${ttsConfig.pitch}
      AND volume = ${ttsConfig.volume}
      AND format = ${sqlString(format)}
      AND status = 'ready';
  `);
  if (existing && existsSync(existing.file_path)) {
    return { url: existing.url, created: false };
  }

  const fileName = `${assetId}.mp3`;
  const filePath = join(audioDir, fileName);
  const url = `${ttsConfig.publicBaseUrl}/audio/${fileName}`;
  const audio = await synthesizeWithXfyun(normalizedText, ttsConfig);
  await writeFile(filePath, audio);
  const now = new Date().toISOString();
  await runSql(`
    INSERT INTO audio_assets (
      id, text_hash, text, voice, speed, pitch, volume, format,
      file_path, url, status, created_at, updated_at
    ) VALUES (
      ${sqlString(assetId)},
      ${sqlString(textHash)},
      ${sqlString(normalizedText)},
      ${sqlString(ttsConfig.voice)},
      ${ttsConfig.speed},
      ${ttsConfig.pitch},
      ${ttsConfig.volume},
      ${sqlString(format)},
      ${sqlString(filePath)},
      ${sqlString(url)},
      'ready',
      ${sqlString(now)},
      ${sqlString(now)}
    )
    ON CONFLICT(text_hash, voice, speed, pitch, volume, format) DO UPDATE SET
      file_path = excluded.file_path,
      url = excluded.url,
      status = excluded.status,
      updated_at = excluded.updated_at;
  `);
  return { url, created: true };
}

async function readTtsConfig(options = {}) {
  const stored = await readJson(ttsConfigPath, {});
  const config = normalizeTtsConfig(stored, defaultTtsConfig(), { allowSecretEmpty: true });
  if (options.includeSecrets) {
    return config;
  }
  return {
    ...config,
    apiSecret: config.apiSecret ? '' : '',
    apiSecretConfigured: Boolean(config.apiSecret),
    apiKeyConfigured: Boolean(config.apiKey),
    appIdConfigured: Boolean(config.appId),
  };
}

async function saveTtsConfig(body) {
  const current = await readTtsConfig({ includeSecrets: true });
  const config = normalizeTtsConfig(body, current);
  await writeJson(ttsConfigPath, config);
  return readTtsConfig();
}

function defaultTtsConfig() {
  return {
    appId: xfyunAppId,
    apiKey: xfyunApiKey,
    apiSecret: xfyunApiSecret,
    voice: xfyunVoice,
    speed: xfyunSpeed,
    pitch: xfyunPitch,
    volume: xfyunVolume,
    publicBaseUrl,
  };
}

function normalizeTtsConfig(source, fallback, options = {}) {
  const pickSecret = (key) => {
    const value = source[key];
    if (typeof value === 'string' && value.trim()) {
      return value.trim();
    }
    if (options.allowSecretEmpty && typeof value === 'string') {
      return value.trim();
    }
    return fallback[key] || '';
  };
  return {
    appId: pickSecret('appId'),
    apiKey: pickSecret('apiKey'),
    apiSecret: pickSecret('apiSecret'),
    voice: String(source.voice || fallback.voice || 'xiaoyan').trim(),
    speed: clampTtsNumber(source.speed, fallback.speed, 0, 100),
    pitch: clampTtsNumber(source.pitch, fallback.pitch, 0, 100),
    volume: clampTtsNumber(source.volume, fallback.volume, 0, 100),
    publicBaseUrl: String(source.publicBaseUrl || fallback.publicBaseUrl || `http://localhost:${port}`)
      .replace(/\/+$/, ''),
  };
}

function clampTtsNumber(value, fallback, min, max) {
  const number = Number(value ?? fallback);
  if (!Number.isFinite(number)) {
    return fallback;
  }
  return Math.min(max, Math.max(min, Math.round(number)));
}

function assertTtsConfigured(ttsConfig) {
  if (!ttsConfig.appId || !ttsConfig.apiKey || !ttsConfig.apiSecret) {
    throw new Error('XFYUN_APP_ID, XFYUN_API_KEY and XFYUN_API_SECRET are required');
  }
}

function normalizeTtsText(text) {
  return String(text || '').replace(/\s+/g, ' ').trim();
}

function sha256(value) {
  return createHash('sha256').update(value).digest('hex');
}

async function synthesizeWithXfyun(text, ttsConfig) {
  return new Promise((resolve, reject) => {
    const chunks = [];
    const websocket = new WebSocket(buildXfyunUrl(ttsConfig));
    const timeout = setTimeout(() => {
      websocket.close();
      reject(new Error('TTS request timed out'));
    }, 60000);

    websocket.on('open', () => {
      websocket.send(JSON.stringify({
        common: { app_id: xfyunAppId },
        business: {
          aue: 'lame',
          vcn: ttsConfig.voice,
          speed: ttsConfig.speed,
          pitch: ttsConfig.pitch,
          volume: ttsConfig.volume,
          tte: 'UTF8',
        },
        data: {
          status: 2,
          text: Buffer.from(text, 'utf8').toString('base64'),
        },
      }));
    });

    websocket.on('message', (message) => {
      const payload = JSON.parse(message.toString());
      if (payload.code !== 0) {
        clearTimeout(timeout);
        websocket.close();
        reject(new Error(payload.message || `TTS failed with code ${payload.code}`));
        return;
      }
      if (payload.data?.audio) {
        chunks.push(Buffer.from(payload.data.audio, 'base64'));
      }
      if (payload.data?.status === 2) {
        clearTimeout(timeout);
        websocket.close();
        resolve(Buffer.concat(chunks));
      }
    });

    websocket.on('error', (error) => {
      clearTimeout(timeout);
      reject(error);
    });
  });
}

function buildXfyunUrl(ttsConfig) {
  const host = 'tts-api.xfyun.cn';
  const path = '/v2/tts';
  const date = new Date().toUTCString();
  const signatureOrigin = `host: ${host}\ndate: ${date}\nGET ${path} HTTP/1.1`;
  const signature = createHmac('sha256', ttsConfig.apiSecret)
    .update(signatureOrigin)
    .digest('base64');
  const authorizationOrigin = `api_key="${ttsConfig.apiKey}", algorithm="hmac-sha256", headers="host date request-line", signature="${signature}"`;
  const query = new URLSearchParams({
    authorization: Buffer.from(authorizationOrigin).toString('base64'),
    date,
    host,
  });
  return `wss://${host}${path}?${query}`;
}

function normalizeQuestion(body) {
  const now = Date.now().toString(36);
  const id = String(body.id || `q-${now}`);
  const required = ['module', 'title', 'techCategory', 'techLanguage'];
  for (const field of required) {
    if (!body[field]) {
      throw new Error(`${field} is required`);
    }
  }

  return {
    id,
    module: String(body.module),
    title: String(body.title),
    tags: stringArray(body.tags),
    reviewStatus: body.reviewStatus || 'notMastered',
    checkpoints: stringArray(body.checkpoints),
    answerPoints: stringArray(body.answerPoints),
    followUps: stringArray(body.followUps),
    mistakes: stringArray(body.mistakes),
    techCategory: String(body.techCategory),
    techLanguage: String(body.techLanguage),
    standardAnswer: body.standardAnswer ? String(body.standardAnswer) : '',
    standardAnswerAudioUrl: body.standardAnswerAudioUrl ? String(body.standardAnswerAudioUrl) : '',
    version: body.version == null ? undefined : Number(body.version),
    updatedAt: body.updatedAt || new Date().toISOString(),
  };
}

function questionImportTemplate() {
  return {
    replace: false,
    scopes: [
      { techCategory: 'client', techLanguage: 'android' },
    ],
    questions: [
      {
        id: 'client-android-sample-question',
        module: 'Android 基础',
        title: 'Activity 的启动模式有哪些？各自适合什么场景？',
        tags: ['高频', '基础'],
        reviewStatus: 'notMastered',
        checkpoints: [
          'standard、singleTop、singleTask、singleInstance 的差异',
          '任务栈复用和 onNewIntent 的触发条件',
        ],
        answerPoints: [
          'standard 每次创建新实例，适合普通页面。',
          'singleTop 在栈顶复用实例，适合通知跳转等重复打开场景。',
          'singleTask 会在目标任务栈中复用已有实例，并清理其上的页面。',
        ],
        followUps: [
          'singleTask 和 taskAffinity 有什么关系？',
          'onNewIntent 后为什么通常还要手动处理 intent 数据？',
        ],
        mistakes: [
          '只背启动模式名字，不说明任务栈变化。',
          '误以为 singleTop 任何位置都能复用实例。',
        ],
        techCategory: 'client',
        techLanguage: 'android',
        standardAnswer: 'Activity 启动模式核心是在实例创建和任务栈复用之间做约束。回答时先说明四种模式的实例复用规则，再结合通知页、详情页、首页等场景解释为什么选择对应模式。',
      },
    ],
  };
}

function stringArray(value) {
  if (Array.isArray(value)) {
    return value.map(String).filter(Boolean);
  }
  if (typeof value === 'string') {
    return value.split('\n').map((line) => line.trim()).filter(Boolean);
  }
  return [];
}

async function upsertQuestionRow(question) {
  await runSql(`
    INSERT INTO questions (
      id, tech_category, tech_language, module, title, review_status,
      tags_json, checkpoints_json, answer_points_json, follow_ups_json,
      mistakes_json, standard_answer, standard_answer_audio_url, version, updated_at, deleted_at
    ) VALUES (
      ${sqlString(question.id)},
      ${sqlString(question.techCategory)},
      ${sqlString(question.techLanguage)},
      ${sqlString(question.module)},
      ${sqlString(question.title)},
      ${sqlString(question.reviewStatus || question.seedStatus || 'notMastered')},
      ${sqlJson(question.tags)},
      ${sqlJson(question.checkpoints)},
      ${sqlJson(question.answerPoints)},
      ${sqlJson(question.followUps)},
      ${sqlJson(question.mistakes)},
      ${sqlString(question.standardAnswer || '')},
      ${question.standardAnswerAudioUrl ? sqlString(question.standardAnswerAudioUrl) : 'NULL'},
      ${Number(question.version || 1)},
      ${sqlString(question.updatedAt || new Date().toISOString())},
      NULL
    )
    ON CONFLICT(id) DO UPDATE SET
      tech_category = excluded.tech_category,
      tech_language = excluded.tech_language,
      module = excluded.module,
      title = excluded.title,
      review_status = excluded.review_status,
      tags_json = excluded.tags_json,
      checkpoints_json = excluded.checkpoints_json,
      answer_points_json = excluded.answer_points_json,
      follow_ups_json = excluded.follow_ups_json,
      mistakes_json = excluded.mistakes_json,
      standard_answer = excluded.standard_answer,
      standard_answer_audio_url = excluded.standard_answer_audio_url,
      version = excluded.version,
      updated_at = excluded.updated_at,
      deleted_at = NULL;
  `);
}

function rowToQuestion(row) {
  return {
    id: row.id,
    module: row.module,
    title: row.title,
    tags: parseJsonArray(row.tags_json),
    reviewStatus: row.review_status,
    checkpoints: parseJsonArray(row.checkpoints_json),
    answerPoints: parseJsonArray(row.answer_points_json),
    followUps: parseJsonArray(row.follow_ups_json),
    mistakes: parseJsonArray(row.mistakes_json),
    techCategory: row.tech_category,
    techLanguage: row.tech_language,
    standardAnswer: row.standard_answer || '',
    standardAnswerAudioUrl: row.standard_answer_audio_url || '',
    version: Number(row.version || 1),
    updatedAt: row.updated_at,
  };
}

function parseJsonArray(value) {
  try {
    const parsed = JSON.parse(value || '[]');
    return Array.isArray(parsed) ? parsed : [];
  } catch (_) {
    return [];
  }
}

async function appendProgress(body) {
  const records = await readJson(progressPath, []);
  const record = {
    id: `sync-${Date.now().toString(36)}`,
    syncedAt: new Date().toISOString(),
    clientId: body.clientId || 'anonymous',
    techCategory: body.techCategory || '',
    techLanguage: body.techLanguage || '',
    summary: body.summary || {},
    questionStates: body.questionStates || {},
  };
  records.push(record);
  await writeJson(progressPath, records.slice(-1000));
  return { ok: true, record };
}

function demoAuthResponse(body, mode) {
  const account = body?.email || body?.phone || body?.username || 'demo';
  return {
    ok: true,
    mode,
    token: `demo-token-${Buffer.from(String(account)).toString('base64url')}`,
    user: { id: `user-${Buffer.from(String(account)).toString('base64url')}`, account },
  };
}

async function latestVersion() {
  const row = await getSql('SELECT COALESCE(MAX(version), 0) AS version FROM questions;');
  return Number(row?.version || 0);
}

async function nextVersion() {
  return (await latestVersion()) + 1;
}

async function allSql(sql) {
  const { stdout } = await execFileAsync('sqlite3', ['-json', questionsDbPath, sql], { maxBuffer: 20 * 1024 * 1024 });
  if (!stdout.trim()) {
    return [];
  }
  return JSON.parse(stdout);
}

async function getSql(sql) {
  const rows = await allSql(sql);
  return rows[0] || null;
}

async function ensureColumn(table, column, definition) {
  const rows = await allSql(`PRAGMA table_info(${table});`);
  if (rows.some((row) => row.name === column)) {
    return;
  }
  await runSql(`ALTER TABLE ${table} ADD COLUMN ${column} ${definition};`);
}

async function runSql(sql) {
  const { stdout, stderr } = await execFileAsync('sqlite3', [questionsDbPath, sql], {
    maxBuffer: 20 * 1024 * 1024,
  });
  if (stderr.trim()) {
    console.warn(stderr.trim());
  }
  return stdout;
}

function sqlString(value) {
  return `'${String(value ?? '').replaceAll("'", "''")}'`;
}

function sqlJson(value) {
  return sqlString(JSON.stringify(Array.isArray(value) ? value : []));
}

function sqlLike(value) {
  const escaped = String(value).replaceAll("'", "''").replaceAll('%', '\\%').replaceAll('_', '\\_');
  return `'%${escaped}%' ESCAPE '\\'`;
}

async function readBody(request) {
  const chunks = [];
  for await (const chunk of request) {
    chunks.push(chunk);
  }
  if (chunks.length === 0) {
    return {};
  }
  return JSON.parse(Buffer.concat(chunks).toString('utf8'));
}

async function readJson(path, fallback) {
  try {
    return JSON.parse(await readFile(path, 'utf8'));
  } catch (error) {
    if (error.code === 'ENOENT') {
      return fallback;
    }
    throw error;
  }
}

async function writeJson(path, value) {
  await writeFile(path, `${JSON.stringify(value, null, 2)}\n`);
}

async function sendStatic(response, path) {
  const resolved = resolve(path);
  if (!resolved.startsWith(publicDir)) {
    return sendJson(response, { error: 'forbidden' }, 403);
  }
  const content = await readFile(resolved);
  return send(response, 200, content, mimeTypes[extname(resolved)] || 'application/octet-stream');
}

async function sendAudio(request, response, fileName) {
  const safeName = basename(fileName);
  if (!safeName.endsWith('.mp3')) {
    return sendJson(response, { error: 'not found' }, 404);
  }

  const resolvedAudioDir = resolve(audioDir);
  const resolved = resolve(resolvedAudioDir, safeName);
  if (!resolved.startsWith(resolvedAudioDir)) {
    return sendJson(response, { error: 'forbidden' }, 403);
  }

  const fileStat = await stat(resolved);
  const range = request.headers.range;
  if (!range) {
    const content = await readFile(resolved);
    return send(response, 200, content, 'audio/mpeg', {
      'Accept-Ranges': 'bytes',
      'Content-Length': fileStat.size,
      'Cache-Control': 'public, max-age=2592000',
    });
  }

  const match = /^bytes=(\d+)-(\d*)$/.exec(range);
  if (!match) {
    return send(response, 416, '', 'text/plain; charset=utf-8');
  }
  const start = Number(match[1]);
  const end = match[2] ? Number(match[2]) : fileStat.size - 1;
  if (start >= fileStat.size || end >= fileStat.size || start > end) {
    return send(response, 416, '', 'text/plain; charset=utf-8', {
      'Content-Range': `bytes */${fileStat.size}`,
    });
  }
  const content = (await readFile(resolved)).subarray(start, end + 1);
  return send(response, 206, content, 'audio/mpeg', {
    'Accept-Ranges': 'bytes',
    'Content-Length': content.length,
    'Content-Range': `bytes ${start}-${end}/${fileStat.size}`,
    'Cache-Control': 'public, max-age=2592000',
  });
}

function redirect(response, location) {
  response.writeHead(302, corsHeaders({ Location: location }));
  response.end();
}

function sendNoContent(response) {
  response.writeHead(204, corsHeaders());
  response.end();
}

function sendUnauthorized(response) {
  response.writeHead(401, corsHeaders({
    'Content-Type': 'text/plain; charset=utf-8',
    'WWW-Authenticate': 'Basic realm="Interview Bank Admin", charset="UTF-8"',
  }));
  response.end('Admin authentication required');
}

function sendJson(response, body, status = 200) {
  return send(response, status, JSON.stringify(body), 'application/json; charset=utf-8');
}

function send(response, status, body, contentType, extraHeaders = {}) {
  response.writeHead(status, corsHeaders({
    'Content-Type': contentType,
    ...extraHeaders,
  }));
  response.end(body);
}

function corsHeaders(extra = {}) {
  return {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Headers': 'Content-Type, Authorization',
    'Access-Control-Allow-Methods': 'GET, POST, PUT, PATCH, DELETE, OPTIONS',
    ...extra,
  };
}
