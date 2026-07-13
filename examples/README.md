# 示例

手动测试与演示页面。

## 文件

| 文件 | 用途 |
|------|------|
| `classroom.html` | 课堂视频播放测试页。用浏览器打开，验证服务端视频可播放。 |

## classroom.html 使用

```bash
# 1. 启动视频服务
VIDEO_DIR=./data/video bin/server

# 2. 浏览器打开（默认地址 http://localhost:9092）
open examples/classroom.html

# 3. 或指定自定义地址
open "examples/classroom.html?url=http://127.0.0.1:8080/video/intro.mp4"
```

查询参数 `url` 指定视频地址，未传参时回退 `http://localhost:9092/video/quickstart/intro.mp4`。
