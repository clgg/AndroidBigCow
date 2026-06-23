# 技术面试题库后端

这是一个先用于上线验证的轻量后端：题库使用 SQLite 持久化，技术导航和用户进度上报暂时仍使用 `server/data/*.json`。

## 本地运行

```bash
cd server
npm start
```

默认监听 `http://localhost:8080`，后台地址是 `http://localhost:8080/admin`。

后台已内置 HTTP Basic Auth，保护范围包括 `/admin`、`/admin/*`、`/api/admin/*`。本地默认账号是：

- 用户名：`admin`
- 密码：`change-me-now`

公网部署前必须改成环境变量：

```bash
ADMIN_USERNAME=your-name ADMIN_PASSWORD='your-strong-password' npm start
```

## API

- `GET /api/health`：健康检查
- `POST /api/auth/register`：注册占位接口，返回 demo token
- `POST /api/auth/login`：登录占位接口，返回 demo token
- `GET /api/tech/categories`：获取技术导航分类
- `GET /api/questions?category=client&language=android&page=1&pageSize=50`：分页获取具体分类下的题目
- `GET /api/questions/latest?category=client&language=android&sinceVersion=1&limit=100`：增量拉取服务端更新题目
- `GET /api/questions/sync?category=client&language=android&afterVersion=1&limit=100`：增量同步接口，返回更新题和删除题 ID
- `POST /api/progress/sync`：上传收藏、未掌握、下次复习等进度统计
- `GET /api/admin/questions`：后台题目列表
- `POST /api/admin/questions`：后台新增或更新题目
- `POST /api/admin/questions/import`：后台批量导入题目，支持数组或 `{ "questions": [...] }`
- `GET /api/admin/questions/template`：获取批量导入模板
- `POST /api/admin/audio/generate-standard-answers`：为筛选后的题目生成“标准答案”MP3，已存在的相同文案会复用
- `DELETE /api/admin/questions/:id`：后台删除题目
- `GET /api/admin/tech-catalog`：后台读取技术导航
- `PUT /api/admin/tech-catalog`：后台保存技术导航
- `GET /api/admin/progress`：后台查看进度上报

## 批量导入题目

后台页面提供“下载模板”和“导入 JSON”。导入文件可以是下面两种格式之一：

```json
{
  "replace": false,
  "scopes": [
    { "techCategory": "client", "techLanguage": "android" }
  ],
  "questions": [
    {
      "id": "client-android-sample-question",
      "module": "Android 基础",
      "title": "Activity 的启动模式有哪些？各自适合什么场景？",
      "tags": ["高频", "基础"],
      "reviewStatus": "notMastered",
      "checkpoints": ["启动模式差异", "任务栈复用"],
      "answerPoints": ["standard 每次创建新实例", "singleTop 栈顶复用实例"],
      "followUps": ["singleTask 和 taskAffinity 有什么关系？"],
      "mistakes": ["只背名字，不说明任务栈变化"],
      "techCategory": "client",
      "techLanguage": "android",
      "standardAnswer": "这里填写完整标准答案。"
    }
  ]
}
```

`replace: true` 表示按 `scopes` 替换对应技术栈题库：文件中存在的题目会新增或更新，同一 `techCategory` + `techLanguage` 下不在文件里的旧题会被软删除并进入增量同步的删除列表。只想增量新增/更新时保持 `replace: false` 或省略该字段。

也可以直接上传题目数组：

```json
[
  {
    "id": "client-ios-arc-001",
    "module": "iOS 内存管理",
    "title": "ARC 的基本原理是什么？",
    "tags": ["iOS", "基础"],
    "reviewStatus": "notMastered",
    "checkpoints": ["引用计数", "强弱引用"],
    "answerPoints": ["ARC 由编译器插入 retain/release 管理对象生命周期。"],
    "followUps": ["循环引用如何处理？"],
    "mistakes": ["误以为 ARC 等于 GC。"],
    "techCategory": "client",
    "techLanguage": "ios",
    "standardAnswer": "这里填写完整标准答案。"
  }
]
```

导入时如果 `id` 已存在会更新原题，不存在则新增。题库保存到：

```text
server/data/questions.db
```

首次启动时如果数据库为空，会自动从旧的 `server/data/questions.json` 导入一次。

## 标准答案语音合成

后台“题目筛选”区域提供“生成标准答案音频”按钮。它只处理 `standardAnswer` 字段，不会合成题目标题、考察点、追问或易错点。

音频生成规则：

- 相同标准答案文案 + 相同发音人/语速/音调/音量/格式，只调用一次科大讯飞；
- 生成后的 MP3 保存在 `server/data/audio/*.mp3`；
- 题目接口会返回 `standardAnswerAudioUrl`，客户端据此显示播放按钮；
- 如果后台修改了标准答案，保存题目会清空旧音频 URL，需要重新生成。

需要配置科大讯飞 WebSocket 认证信息：

```bash
XFYUN_APP_ID=your-app-id
XFYUN_API_KEY=your-api-key
XFYUN_API_SECRET=your-api-secret
PUBLIC_BASE_URL=http://54.150.9.209/interview
```

可选参数：

```bash
XFYUN_TTS_VOICE=xiaoyan
XFYUN_TTS_SPEED=50
XFYUN_TTS_PITCH=50
XFYUN_TTS_VOLUME=50
```

默认发音人使用 `xiaoyan`。如果在讯飞控制台选择了其他第一个发音人，可以把 `XFYUN_TTS_VOICE` 改成对应发音人参数。

## 部署到你的服务器

服务器 `http://54.150.9.209/` 目前能访问到 Nginx。推荐部署方式：

```bash
scp -r server root@54.150.9.209:/opt/interview-bank-server
ssh root@54.150.9.209
cd /opt/interview-bank-server
ADMIN_USERNAME=your-name ADMIN_PASSWORD='your-strong-password' npm start
```

如果直接让 Node 监听 80 端口，需要用 `PORT=80 npm start` 并具备权限。更推荐用 Nginx 反向代理到 `127.0.0.1:8080`。

也可以使用内置部署脚本。它会把服务复制到 `/opt/interview-bank-server`，创建 `systemd` 服务，并把 `/admin` 和 `/api` 代理到 Node：

```bash
cd server
chmod +x deploy/deploy.sh
SERVER_USER=ubuntu ADMIN_USERNAME=admin ADMIN_PASSWORD='your-strong-password' ./deploy/deploy.sh
```

如果服务器登录用户不是 `ubuntu`，把 `SERVER_USER` 改成实际用户，例如 `root`。

Nginx 示例：

```nginx
location / {
  proxy_pass http://127.0.0.1:8080;
  proxy_set_header Host $host;
  proxy_set_header X-Real-IP $remote_addr;
}
```
