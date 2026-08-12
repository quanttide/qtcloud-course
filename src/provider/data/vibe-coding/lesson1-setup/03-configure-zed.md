# 场景3：Zed Agent 配置 DeepSeek 密钥

对应课时：[课时1：开发环境搭建](index.md)

## 前置依赖

- 已完成 [场景1：Zed 的安装与初始化](sense1.md)
- 已完成 [场景2：注册并获取 DeepSeek 密钥](sense2.md)
- 已复制 DeepSeek API 密钥到剪贴板

## 操作步骤

1. 在 Zed 中点击左上角**星星图标**，打开 Zed Agent 面板
2. 点击 Zed Agent 右下角倒数第二个按钮 **"Select a model"**
3. 点击 **Configure**，进入模型配置页面
4. 点击 **LLM Provider**，进入 API 密钥配置页面
5. 下拉列表找到 **DeepSeek**，填入之前复制的 API 密钥
6. 关闭配置页面，回到 Zed Agent，输入一条消息尝试对话

## 验证

在 Zed Agent 中输入 `"hello"` 或 `"你好"`，若 DeepSeek 正常返回回复即表示配置完成。
