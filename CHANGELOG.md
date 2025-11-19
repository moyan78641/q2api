# 修复日志

## 2025-11-19 修复 + 安全增强

### 🔧 问题修复

#### 问题1: 缺少 `/v1/models` 端点

**症状:** 项目缺少获取模型列表的API端点

**原因:** 代码中未实现该端点

**修复:**
- 在 `app.py` 中添加了 `/v1/models` 端点 (第464-499行)
- 返回静态模型列表: `claude-3.5-sonnet`, `claude-sonnet-4`, `claude-sonnet-4.5`
- 支持两种认证方式: `Authorization: Bearer <key>` 和 `x-api-key: <key>`

#### 问题2: `/v1/messages` 端点返回401错误

**症状:**
- `/v1/chat/completions` 使用 `Authorization: Bearer <key>` 正常工作
- `/v1/messages` 使用相同的 API key 返回 401 Unauthorized

**原因:**
- Claude Messages API 标准使用 `x-api-key` header进行认证
- 项目的 `require_account` 依赖函数只检查 `Authorization` header
- 导致使用Claude官方客户端SDK或按照Claude API标准发送请求时认证失败

**修复:**
- 修改 `require_account` 函数 (app.py:455-458行)
- 现在同时支持两种认证header:
  - `Authorization: Bearer <key>` (OpenAI风格)
  - `x-api-key: <key>` (Claude官方风格)
- 如果两个header都存在,优先使用 `Authorization`

### 🔐 安全增强

#### 增强1: Web控制台API Key认证保护

**背景:**
- 之前Web管理控制台(`ENABLE_CONSOLE="true"`)可以直接访问,没有任何认证
- 任何人都可以访问控制台管理账号、查看配置,存在安全风险

**改进:**
1. **后端保护** (app.py)
   - 新增 `require_console_auth` 依赖函数 (第859-865行)
   - 所有控制台相关端点添加认证保护:
     - `POST /v2/auth/start`
     - `GET /v2/auth/status/{auth_id}`
     - `POST /v2/auth/claim/{auth_id}`
     - `POST /v2/accounts`
     - `GET /v2/accounts`
     - `GET /v2/accounts/{account_id}`
     - `DELETE /v2/accounts/{account_id}`
     - `PATCH /v2/accounts/{account_id}`
     - `POST /v2/accounts/{account_id}/refresh`

2. **前端保护** (frontend/index.html)
   - 添加登录模态框,页面加载时自动弹出要求输入API Key
   - API Key存储在sessionStorage中,刷新页面需要重新输入
   - 所有API请求自动携带认证header
   - 添加"注销"按钮,点击后清除sessionStorage并刷新页面
   - 支持Enter键快捷登录
   - 401错误自动重新要求输入API Key

**工作原理:**
- 如果 `OPENAI_KEYS` 为空:开发模式,控制台可直接访问无需认证
- 如果 `OPENAI_KEYS` 已配置:必须输入白名单中的Key才能访问控制台

**安全性:**
- API Key仅存储在sessionStorage,关闭浏览器自动清除
- 所有管理操作需要API Key验证
- 前后端双重保护

#### 增强2: Docker Compose 配置优化

**背景:**
- 之前需要单独创建 `.env` 文件配置环境变量
- 配置分散,不方便管理和部署

**改进:**
1. **优化 docker-compose.yml**
   - 不再依赖 `.env` 文件
   - 所有环境变量直接在 `docker-compose.yml` 中配置
   - 添加详细的中文注释说明每个配置项
   - 配置项按类别分组(安全配置、账号管理、网络配置、功能开关)
   - 默认使用 `build: .` 构建本地镜像,可选择使用远程镜像

2. **新增功能:**
   - 健康检查配置
   - 资源限制配置(可选)
   - 网络配置(可选)
   - 数据持久化配置

**使用方式:**
```bash
# 1. 编辑 docker-compose.yml,修改 OPENAI_KEYS 等配置
# 2. 启动服务
docker-compose up -d

# 查看日志
docker-compose logs -f

# 停止服务
docker-compose down
```

### 📝 文档更新

**README.md 更新:**
1. 在 "完整 API 端点列表" 部分添加了 `/v1/models` 端点说明
2. 在 "OpenAI 兼容 API" 部分添加了模型列表获取示例
3. 在 "Claude Messages API" 部分添加了认证方式说明,明确两种header的支持情况

**docker-compose.yml 更新:**
1. 重构配置文件结构,添加详细注释
2. 所有配置项直接在文件中设置,无需.env
3. 添加安全提示和最佳实践建议

### 🧪 测试脚本

创建了两个测试脚本用于验证修复:
- `test_api.sh` - Linux/Mac版本
- `test_api.bat` - Windows版本

测试覆盖:
- ✅ GET /v1/models (Authorization header)
- ✅ GET /v1/models (x-api-key header)
- ✅ POST /v1/messages (x-api-key header)
- ✅ POST /v1/messages (Authorization header)
- ✅ POST /v1/chat/completions (Authorization header)

### 🚀 部署指南

#### 使用Docker Compose (推荐):

```bash
# 1. 编辑 docker-compose.yml 配置环境变量
nano docker-compose.yml

# 2. 设置 OPENAI_KEYS (重要!)
# OPENAI_KEYS: "your-secret-key-here"

# 3. 启动服务
docker-compose up -d

# 4. 查看日志
docker-compose logs -f q2api

# 5. 访问服务
# Web控制台: http://localhost:8000/
# API文档: http://localhost:8000/docs
# 健康检查: http://localhost:8000/healthz
```

#### 使用Docker (手动):

```bash
# 1. 构建镜像
docker build -t q2api:latest .

# 2. 创建数据目录
mkdir -p ./data

# 3. 启动容器
docker run -d \
  --name q2api \
  -p 8000:8000 \
  -v $(pwd)/data:/app/data \
  -e OPENAI_KEYS="your-key-here" \
  -e ENABLE_CONSOLE="true" \
  --restart unless-stopped \
  q2api:latest

# 4. 查看日志
docker logs -f q2api
```

#### 使用Python直接运行:

```bash
# 1. 安装依赖
pip install -r requirements.txt

# 2. 配置环境变量 (.env文件)
cp .env.example .env
nano .env

# 3. 启动服务
python -m uvicorn app:app --host 0.0.0.0 --port 8000
```

### 💡 使用建议

#### 生产环境安全配置:

1. **必须设置 OPENAI_KEYS:**
```yaml
OPENAI_KEYS: "strong-random-key-1,strong-random-key-2"
```

2. **启用HTTPS:**
使用Nginx反向代理+Let's Encrypt证书

3. **限制访问来源:**
配置防火墙规则或使用Docker网络隔离

4. **定期备份数据:**
```bash
# 备份数据库
cp ./data/data.sqlite3 ./backups/data_$(date +%Y%m%d).sqlite3
```

5. **监控日志:**
```bash
docker-compose logs -f --tail=100 q2api
```

### 🔍 技术细节

#### 认证流程

**API端点认证:**
```python
async def require_account(
    authorization: Optional[str] = Header(default=None),
    x_api_key: Optional[str] = Header(default=None, alias="x-api-key")
) -> Dict[str, Any]:
    # 优先使用 Authorization header, 其次使用 x-api-key
    bearer = _extract_bearer(authorization) if authorization else x_api_key
    return await resolve_account_for_key(bearer)
```

**控制台端点认证:**
```python
async def require_console_auth(...):
    """仅验证API Key,不需要AWS账号"""
    bearer = _extract_bearer(authorization) if authorization else x_api_key
    if ALLOWED_API_KEYS:
        if not bearer or bearer not in ALLOWED_API_KEYS:
            raise HTTPException(status_code=401)
    return True
```

#### 前端认证流程

1. 页面加载时检查sessionStorage中的API Key
2. 如果不存在,弹出模态框要求输入
3. 输入后通过 `/healthz` 端点验证
4. 验证通过后存储在sessionStorage
5. 所有API请求自动添加 `Authorization: Bearer <key>` header
6. 401错误时自动清除Key并要求重新输入

#### 模型列表端点

```python
@app.get("/v1/models")
async def list_models(...):
    # 认证逻辑
    bearer = _extract_bearer(authorization) if authorization else x_api_key
    if ALLOWED_API_KEYS:
        if not bearer or bearer not in ALLOWED_API_KEYS:
            raise HTTPException(status_code=401)

    # 返回模型列表
    return {
        "object": "list",
        "data": [
            {"id": "claude-3.5-sonnet", ...},
            {"id": "claude-sonnet-4", ...},
            {"id": "claude-sonnet-4.5", ...},
        ]
    }
```

### 📊 兼容性说明

修复后的项目完全兼容:
- ✅ Anthropic Python SDK (使用 `x-api-key`)
- ✅ OpenAI Python SDK (使用 `Authorization: Bearer`)
- ✅ Claude Code (使用 `x-api-key`)
- ✅ 任何使用标准 OpenAI/Claude API 的客户端
- ✅ Web控制台需要API Key认证(如果配置了OPENAI_KEYS)

### ⚠️ 已知限制

1. **模型列表静态:** 模型列表是静态的,不从Amazon Q动态获取
2. **多实例部署:** AUTH_SESSIONS存储在内存,多实例部署需要共享状态
3. **API Key存储:** sessionStorage存储,关闭浏览器需要重新输入

### 📁 相关文件

**修改的文件:**
- `app.py` - 主应用逻辑 (添加认证保护)
- `frontend/index.html` - Web控制台 (添加登录功能)
- `docker-compose.yml` - Docker Compose配置
- `README.md` - 文档
- `CHANGELOG.md` - 本文档

**新增的文件:**
- `test_api.sh` - Linux/Mac测试脚本
- `test_api.bat` - Windows测试脚本

### 🎯 总结

本次更新实现了三个主要目标:

1. **✅ 功能完善:** 添加 `/v1/models` 端点,支持双重认证
2. **✅ 安全增强:** Web控制台添加API Key认证保护
3. **✅ 部署优化:** Docker Compose配置直接管理环境变量

这些改进显著提升了项目的安全性、易用性和部署便利性!
