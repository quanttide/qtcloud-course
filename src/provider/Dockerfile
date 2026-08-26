# 课程云 provider：多阶段构建 + 内置 vibe-coding 课程数据。
# 启动时先 seed（幂等，写入 OSS——FC 可读写对象存储、容器回收数据仍在）再启动服务。
# OSS 配置（QTCLOUD_OSS_*）由 FC 环境变量注入（见 manifests/terraform/fc.tf）。

FROM golang:1.26-alpine AS build

RUN apk add --no-cache gcc musl-dev

WORKDIR /src

ARG GOPROXY=https://goproxy.cn,direct
ENV GOPROXY=${GOPROXY}

COPY go.mod go.sum ./
RUN go mod download

COPY . .
RUN CGO_ENABLED=0 go build -trimpath -ldflags="-s -w" -o /out/course-server ./cmd/server
RUN CGO_ENABLED=0 go build -trimpath -ldflags="-s -w" -o /out/course-seed ./cmd/seed
RUN CGO_ENABLED=0 go build -trimpath -ldflags="-s -w" -o /out/course-seed-catalog ./cmd/seed-catalog

FROM alpine:3.20

RUN addgroup -S app && adduser -S -G app app
COPY --from=build /out/course-server /usr/local/bin/course-server
COPY --from=build /out/course-seed /usr/local/bin/course-seed
COPY --from=build /out/course-seed-catalog /usr/local/bin/course-seed-catalog

# vibe-coding 课程数据（场景 + 视频 URL 源）
ARG VIBE_CODING_DIR=./data/vibe-coding
COPY ${VIBE_CODING_DIR} /data/vibe-coding

USER app
EXPOSE 8080

# 启动：先 seed 氛围编程场景（vibe-coding，含视频），再 seed 公开课程目录（5 门课 + 生产实习正文），
# 最后服务；数据写入 OSS 桶（QTCLOUD_COURSE_STORE=oss，配置由 FC 环境变量注入），发版更新
CMD ["sh", "-c", "QTCLOUD_COURSE_STORE=oss /usr/local/bin/course-seed --dir /data/vibe-coding && QTCLOUD_COURSE_STORE=oss /usr/local/bin/course-seed-catalog && QTCLOUD_COURSE_STORE=oss /usr/local/bin/course-server"]
