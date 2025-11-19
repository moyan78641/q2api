# 使用官方 Python 轻量级镜像
FROM python:3.11-slim

# 设置工作目录
WORKDIR /app

# 设置环境变量，防止 Python 生成 .pyc 文件和缓冲 stdout/stderr
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1

# 安装依赖
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# 复制项目文件
COPY . .

# 设置默认环境变量 (可以在 docker run 时覆盖)
ENV PORT=8000
ENV OPENAI_KEYS=""
ENV MAX_ERROR_COUNT=100
ENV HTTP_PROXY=""
ENV ENABLE_CONSOLE="true"

# 暴露端口
EXPOSE $PORT

# 启动命令，使用 shell 形式以支持变量扩展
CMD ["sh", "-c", "uvicorn app:app --host 0.0.0.0 --port ${PORT}"]
