const state = {
  questions: [],
  catalog: [],
  progress: [],
  ttsConfig: null,
  selectedId: null,
  audioJobTimer: null,
};

const $ = (selector) => document.querySelector(selector);

const fields = [
  'id',
  'module',
  'techCategory',
  'techLanguage',
  'title',
  'tags',
  'checkpoints',
  'standardAnswer',
  'answerPoints',
  'followUps',
  'mistakes',
];

const requiredCatalogEntries = [
  {
    id: 'algorithm',
    label: '算法',
    description: '数据结构、算法题、复杂度与编码实现',
    languages: [
      {
        id: 'general',
        label: '通用算法',
        description: 'Java / Python / C / C++ / JavaScript / Go 多语言解法',
      },
    ],
  },
];

$('#refreshButton').addEventListener('click', loadAll);
$('#newQuestionButton').addEventListener('click', () => selectQuestion(null));
$('#generateAudioButton').addEventListener('click', generateStandardAnswerAudio);
$('#downloadTemplateButton').addEventListener('click', downloadTemplate);
$('#importBundledButton').addEventListener('click', importBundledQuestions);
$('#importButton').addEventListener('click', () => $('#importFileInput').click());
$('#importFileInput').addEventListener('change', importQuestions);
$('#deleteButton').addEventListener('click', deleteSelected);
$('#questionForm').addEventListener('submit', saveQuestion);
$('#ttsConfigForm').addEventListener('submit', saveTtsConfig);
$('#saveCatalogButton').addEventListener('click', saveCatalog);
$('#categoryFilter').addEventListener('change', () => {
  renderLanguageFilter();
  renderQuestions();
});
$('#languageFilter').addEventListener('change', renderQuestions);
$('#searchInput').addEventListener('input', renderQuestions);

loadAll();

async function loadAll() {
  const [questions, catalog, progress, ttsConfig] = await Promise.all([
    request('/api/admin/questions'),
    request('/api/admin/tech-catalog'),
    request('/api/admin/progress'),
    request('/api/admin/tts-config'),
  ]);
  state.questions = questions;
  state.catalog = withRequiredCatalogEntries(catalog);
  state.progress = progress;
  state.ttsConfig = ttsConfig;
  $('#questionCount').textContent = questions.length;
  $('#categoryCount').textContent = state.catalog.length;
  $('#progressCount').textContent = progress.length;
  $('#catalogEditor').value = JSON.stringify(state.catalog, null, 2);
  renderTtsConfig();
  renderCategoryFilter();
  renderQuestions();
  if (!state.selectedId) {
    selectQuestion(questions[0] || null);
  }
}

function renderTtsConfig() {
  const config = state.ttsConfig || {};
  const form = $('#ttsConfigForm');
  form.elements.appId.value = config.appId || '';
  form.elements.apiKey.value = config.apiKey || '';
  form.elements.apiSecret.value = '';
  form.elements.apiSecret.placeholder = config.apiSecretConfigured
    ? '已配置，留空保持当前密钥'
    : '请输入 APISecret';
  form.elements.voice.value = config.voice || 'xiaoyan';
  form.elements.speed.value = config.speed ?? 50;
  form.elements.pitch.value = config.pitch ?? 50;
  form.elements.volume.value = config.volume ?? 50;
  form.elements.publicBaseUrl.value = config.publicBaseUrl || '';
}

async function request(path, options = {}) {
  const response = await fetch(path, {
    headers: { 'Content-Type': 'application/json' },
    credentials: 'same-origin',
    ...options,
  });
  const raw = await response.text();
  let payload;
  try {
    payload = raw ? JSON.parse(raw) : null;
  } catch (_) {
    const preview = raw.trim().slice(0, 80).replace(/\s+/g, ' ');
    throw new Error(
      `接口 ${path} 返回的不是 JSON，而是 ${preview || '空内容'}。请确认后台服务已部署最新代码、登录未过期，且反向代理没有把接口转到 HTML 页面。`,
    );
  }
  if (!response.ok) {
    throw new Error(payload.error || response.statusText);
  }
  return payload;
}

function renderCategoryFilter() {
  $('#categoryFilter').innerHTML = [
    '<option value="">全部方向</option>',
    ...state.catalog.map((category) => `<option value="${escapeHtml(category.id)}">${escapeHtml(category.label)}</option>`),
  ].join('');
  renderLanguageFilter();
}

function renderLanguageFilter() {
  const categoryId = $('#categoryFilter').value;
  const category = state.catalog.find((item) => item.id === categoryId);
  const languages = category ? category.languages : state.catalog.flatMap((item) => item.languages || []);
  $('#languageFilter').innerHTML = [
    '<option value="">全部语言</option>',
    ...languages.map((language) => `<option value="${escapeHtml(language.id)}">${escapeHtml(language.label)}</option>`),
  ].join('');
}

function renderQuestions() {
  const categoryId = $('#categoryFilter').value;
  const languageId = $('#languageFilter').value;
  const query = $('#searchInput').value.trim().toLowerCase();
  const questions = state.questions.filter((question) => {
    const text = [
      question.module,
      question.title,
      question.techCategory,
      question.techLanguage,
      ...(question.tags || []),
    ].join(' ').toLowerCase();
    return (!categoryId || question.techCategory === categoryId) &&
      (!languageId || question.techLanguage === languageId) &&
      (!query || text.includes(query));
  });

  $('#filteredQuestionCount').textContent =
    `当前筛选 ${questions.length} 道 / 共 ${state.questions.length} 道`;

  $('#questionList').innerHTML = questions.map((question) => `
    <article class="question-item ${question.id === state.selectedId ? 'active' : ''}" data-id="${escapeHtml(question.id)}">
      <h3>${escapeHtml(question.title)}</h3>
      <p>${escapeHtml(question.module)} · ${escapeHtml(question.techCategory)} / ${escapeHtml(question.techLanguage)}${question.standardAnswerAudioUrl ? ' · 已有音频' : ''}</p>
    </article>
  `).join('');

  document.querySelectorAll('.question-item').forEach((item) => {
    item.addEventListener('click', () => {
      selectQuestion(state.questions.find((question) => question.id === item.dataset.id));
    });
  });
}

function selectQuestion(question) {
  state.selectedId = question?.id || null;
  const form = $('#questionForm');
  fields.forEach((field) => {
    const input = form.elements[field];
    const value = question?.[field] || '';
    input.value = Array.isArray(value) ? value.join('\n') : value;
  });
  $('#deleteButton').disabled = !question;
  renderQuestions();
}

async function saveQuestion(event) {
  event.preventDefault();
  const form = event.currentTarget;
  const payload = {};
  fields.forEach((field) => {
    const value = form.elements[field].value.trim();
    payload[field] = ['tags', 'checkpoints', 'answerPoints', 'followUps', 'mistakes'].includes(field)
      ? value.split('\n').map((line) => line.trim()).filter(Boolean)
      : value;
  });
  $('#saveStatus').textContent = '保存中...';
  const saved = await request('/api/admin/questions', {
    method: 'POST',
    body: JSON.stringify(payload),
  });
  const index = state.questions.findIndex((question) => question.id === saved.id);
  if (index >= 0) {
    state.questions[index] = saved;
  } else {
    state.questions.unshift(saved);
  }
  state.selectedId = saved.id;
  $('#questionCount').textContent = state.questions.length;
  $('#saveStatus').textContent = '已保存';
  renderQuestions();
}

async function deleteSelected() {
  if (!state.selectedId || !confirm('确认删除这道题？')) {
    return;
  }
  await request(`/api/admin/questions/${encodeURIComponent(state.selectedId)}`, { method: 'DELETE' });
  state.questions = state.questions.filter((question) => question.id !== state.selectedId);
  state.selectedId = null;
  $('#questionCount').textContent = state.questions.length;
  selectQuestion(state.questions[0] || null);
}

async function downloadTemplate() {
  const template = await request('/api/admin/questions/template');
  const blob = new Blob([`${JSON.stringify(template, null, 2)}\n`], {
    type: 'application/json',
  });
  const url = URL.createObjectURL(blob);
  const link = document.createElement('a');
  link.href = url;
  link.download = 'question-import-template.json';
  link.click();
  URL.revokeObjectURL(url);
}

async function importQuestions(event) {
  const file = event.currentTarget.files[0];
  event.currentTarget.value = '';
  if (!file) {
    return;
  }

  try {
    $('#importStatus').textContent = '导入中...';
    const content = await file.text();
    if (content.trimStart().startsWith('<')) {
      throw new Error('当前选择的是 HTML 页面，不是 JSON 文件。请导入 server/data/question_import_optimized_2026_06.json，或先把接口返回内容保存为 .json 文件。');
    }
    const payload = JSON.parse(content);
    const result = await request('/api/admin/questions/import', {
      method: 'POST',
      body: JSON.stringify(payload),
    });
    $('#importStatus').textContent =
      `导入完成：新增 ${result.created} 道，更新 ${result.updated} 道，删除 ${result.deleted || 0} 道，当前共 ${result.total} 道。`;
    await loadAll();
  } catch (error) {
    $('#importStatus').textContent = `导入失败：${error.message}`;
  }
}

async function importBundledQuestions() {
  if (!confirm('将导入服务端内置题库文件，并按文件中的 scopes 替换对应技术栈题库。确认继续？')) {
    return;
  }

  const button = $('#importBundledButton');
  button.disabled = true;
  try {
    $('#importStatus').textContent = '正在导入服务端内置题库...';
    const result = await request('/api/admin/questions/import-bundled', {
      method: 'POST',
      body: JSON.stringify({}),
    });
    $('#importStatus').textContent =
      `导入完成：新增 ${result.created} 道，更新 ${result.updated} 道，删除 ${result.deleted || 0} 道，当前共 ${result.total} 道。`;
    await loadAll();
  } catch (error) {
    $('#importStatus').textContent = `导入失败：${error.message}`;
  } finally {
    button.disabled = false;
  }
}

async function generateStandardAnswerAudio() {
  const category = $('#categoryFilter').value;
  const language = $('#languageFilter').value;
  const query = $('#searchInput').value.trim();
  const filteredCountText = $('#filteredQuestionCount').textContent;
  if (!confirm(`${filteredCountText}\n\n将只为“标准答案”生成 MP3，已生成过的相同文案会复用。确认继续？`)) {
    return;
  }

  const button = $('#generateAudioButton');
  button.disabled = true;
  $('#audioStatus').textContent = '标准答案音频任务创建中...';
  resetAudioProgress();
  try {
    const job = await request('/api/admin/audio/generate-standard-answers', {
      method: 'POST',
      body: JSON.stringify({
        category,
        language,
        query,
        limit: 500,
      }),
    });
    renderAudioProgress(job);
    pollAudioJob(job.id);
  } catch (error) {
    $('#audioStatus').textContent = `音频生成失败：${error.message}`;
    button.disabled = false;
  }
}

function resetAudioProgress() {
  if (state.audioJobTimer) {
    clearTimeout(state.audioJobTimer);
    state.audioJobTimer = null;
  }
  $('#audioProgress').hidden = false;
  $('#audioProgressText').textContent = '0 / 0';
  $('#audioProgressPercent').textContent = '0%';
  $('#audioProgressBar').value = 0;
  $('#audioCurrentQuestion').textContent = '';
  $('#audioProgressDetail').textContent = '';
}

async function pollAudioJob(jobId) {
  try {
    const job = await request(`/api/admin/audio/jobs/${encodeURIComponent(jobId)}`);
    renderAudioProgress(job);
    if (job.status === 'running') {
      state.audioJobTimer = setTimeout(() => pollAudioJob(jobId), 1000);
      return;
    }
    $('#generateAudioButton').disabled = false;
    await loadAll();
  } catch (error) {
    $('#audioStatus').textContent = `获取音频进度失败：${error.message}`;
    $('#generateAudioButton').disabled = false;
  }
}

function renderAudioProgress(job) {
  $('#audioProgress').hidden = false;
  $('#audioProgressText').textContent = `${job.processed} / ${job.total}`;
  $('#audioProgressPercent').textContent = `${job.percent}%`;
  $('#audioProgressBar').value = job.percent;
  $('#audioCurrentQuestion').textContent = job.currentQuestion
    ? `正在处理：${job.currentQuestion.title}`
    : '';
  $('#audioProgressDetail').textContent =
    `新生成 ${job.created} 条，复用 ${job.reused} 条，更新题目 ${job.updated} 道，失败/跳过 ${job.skipped} 道。`;
  if (job.status === 'running') {
    $('#audioStatus').textContent = '标准答案音频生成中，请不要关闭页面...';
  } else if (job.status === 'completed') {
    $('#audioStatus').textContent = '标准答案音频生成完成。';
  } else if (job.status === 'completed_with_errors') {
    const firstError = job.failures?.[0]?.error || '部分题目失败';
    $('#audioStatus').textContent = `音频生成完成，但有失败项：${firstError}`;
  } else {
    $('#audioStatus').textContent = '音频生成任务失败。';
  }
}

async function saveTtsConfig(event) {
  event.preventDefault();
  const form = event.currentTarget;
  const payload = {
    appId: form.elements.appId.value.trim(),
    apiKey: form.elements.apiKey.value.trim(),
    apiSecret: form.elements.apiSecret.value.trim(),
    voice: form.elements.voice.value.trim(),
    speed: Number(form.elements.speed.value || 50),
    pitch: Number(form.elements.pitch.value || 50),
    volume: Number(form.elements.volume.value || 50),
    publicBaseUrl: form.elements.publicBaseUrl.value.trim(),
  };
  $('#ttsConfigStatus').textContent = '保存中...';
  try {
    state.ttsConfig = await request('/api/admin/tts-config', {
      method: 'PUT',
      body: JSON.stringify(payload),
    });
    renderTtsConfig();
    $('#ttsConfigStatus').textContent = '已保存，后续生成音频会使用新配置';
  } catch (error) {
    $('#ttsConfigStatus').textContent = `保存失败：${error.message}`;
  }
}

async function saveCatalog() {
  const catalog = JSON.parse($('#catalogEditor').value);
  state.catalog = withRequiredCatalogEntries(await request('/api/admin/tech-catalog', {
    method: 'PUT',
    body: JSON.stringify(catalog),
  }));
  $('#categoryCount').textContent = state.catalog.length;
  renderCategoryFilter();
}

function withRequiredCatalogEntries(catalog) {
  const normalized = Array.isArray(catalog) ? [...catalog] : [];
  for (const required of requiredCatalogEntries) {
    const existing = normalized.find((item) => item?.id === required.id);
    if (!existing) {
      normalized.push(required);
      continue;
    }
    existing.languages = Array.isArray(existing.languages)
      ? [...existing.languages]
      : [];
    for (const language of required.languages) {
      if (!existing.languages.some((item) => item?.id === language.id)) {
        existing.languages.push(language);
      }
    }
  }
  return normalized;
}

function escapeHtml(value) {
  return String(value ?? '')
    .replaceAll('&', '&amp;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;')
    .replaceAll('"', '&quot;');
}
