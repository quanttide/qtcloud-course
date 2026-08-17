# 课程云 provider：多阶段构建 + 内置 vibe-coding 课程数据。
# 启动时先 seed（幂等，重建 SQLite）再启动服务——数据源固定在镜像内，发版即更新。

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

# 旧 vibe-coding 课程数据保留在镜像中，仅供后续管理端/兼容迁移使用。
ARG VIBE_CODING_DIR=./data/vibe-coding
COPY ${VIBE_CODING_DIR} /data/vibe-coding

USER app
EXPOSE 8080

# 启动：seed 公开课程目录（5 门课 + 生产实习真实正文）再服务；
# DB 在容器内临时盘（课程数据源固定，发版更新）
CMD ["sh", "-c", "DB_PATH=/tmp/course.db /usr/local/bin/course-seed-catalog && DB_PATH=/tmp/course.db /usr/local/bin/course-server"]
