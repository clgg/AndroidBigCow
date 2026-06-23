const state = {
  questions: [],
  catalog: [],
  progress: [],
  selectedId: null,
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

$('#refreshButton').addEventListener('click', loadAll);
$('#newQuestionButton').addEventListener('click', () => selectQuestion(null));
$('#downloadTemplateButton').addEventListener('click', downloadTemplate);
$('#importButton').addEventListener('click', () => $('#importFileInput').click());
$('#importFileInput').addEventListener('change', importQuestions);
$('#deleteButton').addEventListener('click', deleteSelected);
$('#questionForm').addEventListener('submit', saveQuestion);
$('#saveCatalogButton').addEventListener('click', saveCatalog);
$('#categoryFilter').addEventListener('change', () => {
  renderLanguageFilter();
  renderQuestions();
});
$('#languageFilter').addEventListener('change', renderQuestions);
$('#searchInput').addEventListener('input', renderQuestions);

loadAll();

async function loadAll() {
  const [questions, catalog, progress] = await Promise.all([
    request('/api/admin/questions'),
    request('/api/admin/tech-catalog'),
    request('/api/admin/progress'),
  ]);
  state.questions = questions;
  state.catalog = catalog;
  state.progress = progress;
  $('#questionCount').textContent = questions.length;
  $('#categoryCount').textContent = catalog.length;
  $('#progressCount').textContent = progress.length;
  $('#catalogEditor').value = JSON.stringify(catalog, null, 2);
  renderCategoryFilter();
  renderQuestions();
  if (!state.selectedId) {
    selectQuestion(questions[0] || null);
  }
}

async function request(path, options = {}) {
  const response = await fetch(path, {
    headers: { 'Content-Type': 'application/json' },
    credentials: 'same-origin',
    ...options,
  });
  const payload = await response.json();
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

  $('#questionList').innerHTML = questions.map((question) => `
    <article class="question-item ${question.id === state.selectedId ? 'active' : ''}" data-id="${escapeHtml(question.id)}">
      <h3>${escapeHtml(question.title)}</h3>
      <p>${escapeHtml(question.module)} · ${escapeHtml(question.techCategory)} / ${escapeHtml(question.techLanguage)}</p>
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
    const payload = JSON.parse(await file.text());
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

async function saveCatalog() {
  const catalog = JSON.parse($('#catalogEditor').value);
  state.catalog = await request('/api/admin/tech-catalog', {
    method: 'PUT',
    body: JSON.stringify(catalog),
  });
  $('#categoryCount').textContent = state.catalog.length;
  renderCategoryFilter();
}

function escapeHtml(value) {
  return String(value ?? '')
    .replaceAll('&', '&amp;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;')
    .replaceAll('"', '&quot;');
}
