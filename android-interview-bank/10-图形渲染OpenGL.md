# 图形渲染 / OpenGL

## Q: Android 从 View 绘制到屏幕显示的大致链路是什么？

标签：底层 / 图形 / 高频

复习状态：未掌握

考察点：

- ViewRootImpl。
- RenderThread。
- SurfaceFlinger。

答案要点：

- UI 线程通过 ViewRootImpl 触发遍历，完成 measure、layout、draw。
- 硬件加速下绘制命令会记录为 DisplayList，并交给 RenderThread/GPU 执行。
- 应用把渲染结果写入 Surface Buffer。
- SurfaceFlinger 合成多个窗口图层，最终送显。

深挖追问：

- Choreographer 和 VSync 有什么关系？
- UI 线程和 RenderThread 分别卡住会怎样？
- Surface Buffer 队列是什么？

常见误区：

- 认为 onDraw 直接把像素画到屏幕。

## Q: SurfaceView 和 TextureView 有什么区别？

标签：高频 / 图形 / 易混

复习状态：未掌握

考察点：

- 独立 Surface。
- View 层级融合。
- 使用场景。

答案要点：

- SurfaceView 拥有独立 Surface，通常由单独窗口层合成，适合相机、视频、游戏等高性能渲染。
- TextureView 在 View 层级中作为纹理参与合成，支持普通 View 变换、动画和透明。
- SurfaceView 性能和延迟通常更好，但历史上在层级、动画、遮挡方面限制更多。
- TextureView 更灵活，但可能有额外纹理拷贝和性能成本。

深挖追问：

- 为什么视频播放常用 SurfaceView？
- TextureView 截图为什么方便？
- SurfaceView 在 RecyclerView 中有什么坑？

常见误区：

- 只说 SurfaceView 性能好，不分析层级和变换需求。

## Q: OpenGL ES 渲染一张纹理的基本步骤是什么？

标签：OpenGL / 基础 / 高频

复习状态：未掌握

考察点：

- Shader。
- 顶点数据。
- 纹理采样。

答案要点：

- 创建 EGL 环境和 OpenGL 上下文。
- 编写并编译顶点着色器和片段着色器，链接 Program。
- 准备顶点坐标、纹理坐标和纹理对象。
- 绑定 Program、传入矩阵和纹理，调用 glDrawArrays 或 glDrawElements 绘制。

深挖追问：

- 顶点着色器和片段着色器分别做什么？
- 纹理坐标为什么和屏幕坐标方向可能不同？
- OES 外部纹理是什么？

常见误区：

- 背 API 调用顺序但不知道数据如何流动。

## Q: EGL 在 OpenGL ES 中负责什么？

标签：OpenGL / 底层 / 易混

复习状态：未掌握

考察点：

- OpenGL 上下文。
- 渲染目标。
- 平台桥接。

答案要点：

- EGL 是 OpenGL ES 和原生窗口系统之间的接口层。
- EGLDisplay 表示显示连接，EGLContext 表示 OpenGL 状态上下文，EGLSurface 表示渲染目标。
- 在 Android 上通常需要把 Surface、SurfaceTexture 或离屏 Pbuffer 与 EGLSurface 关联。
- 多线程 OpenGL 要特别关注上下文绑定和资源共享。

深挖追问：

- eglMakeCurrent 做什么？
- 离屏渲染如何实现？
- 多个 Context 如何共享纹理？

常见误区：

- 把 EGLContext 和 Android Context 混淆。

## Q: FBO 有什么作用？常见应用场景是什么？

标签：OpenGL / 进阶 / 图形

复习状态：未掌握

考察点：

- 离屏渲染。
- 多 Pass。
- 滤镜。

答案要点：

- FBO 是帧缓冲对象，可以把渲染结果输出到纹理或 Renderbuffer，而不是直接输出到屏幕。
- 常用于滤镜链、多 Pass 渲染、截图、水印、特效和后处理。
- 使用时要创建并绑定纹理附件，检查 framebuffer complete。
- FBO 尺寸、纹理格式和绑定状态错误会导致黑屏或渲染异常。

深挖追问：

- 多级滤镜如何组织 FBO？
- glReadPixels 为什么可能慢？
- FBO 和默认帧缓冲有什么区别？

常见误区：

- 忘记解绑 FBO，导致后续画面渲染到错误目标。

