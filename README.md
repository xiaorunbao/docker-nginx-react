# nginx-react

A docker base image for a Single Page App (eg. React), within nginx server,
clear url, push state friendly by default.

Use the minimalist Nginx image based on Alpine linux (~6 MB).

## Quick start

There are two ways to kick off:

### 1. Start the default container

Link your app with this volume `-v /your/webapp:/app`.

```sh
docker run -d --name myapp -p 3000:80 -v /your/webapp:/app 36node/nginx-react
```

### 2. Dockfile

**Strongly suggest you follow this way**

```sh
FROM 36node/nginx-react:latest

ENV DEBUG=off \
    ENV_PREFIX=APP_ \
    NODE_ENV=production

## Suppose your app is in the dist directory.
COPY ./dist /app
```

Then just publish your images, and run the container from it.

```sh
docker run -d -p 80:80 your_image
```

Take a look at todoMVC examples for more details.

## Runtime env

This is an useful feature.

Some times we will need to start App with different env, here comes the runtime env.
Just set some environments when you start your container.

Then we can use it via:

```
window?._runtime_?.APP_GREETINGS
```

Try to build the examples/todoMVC image, and run it with some env.

```sh
docker run -e APP_GREETINGS="XXXXXX" -d -p 3000:80 todomvc
```

If you don't want to expose all env, just put ENV_PREFIX=APP, then only environments that start with APP will be injected in.

## Environments

This image has following preset env.

* BUILD: Image build time.
* DEBUG: Debug envrionment.
* ENV_PREFIX: All env start with this prefix will be used for subst. See [Runtime env](#runtime-env) section.
* APP_VERSION: App version.
* APP_WORKDIR: the root direactory of your app running in the docker container,
  usally you do not need to change it.
* APP_BASENAME: some times you would want to put several sites under one
  domain, then sub path prefix is required.
* API_GATEWAY & API_PLACEHOLDER: An api call start with a specific path, then the container
  will proxy the request to API_GATEWAY.
* CLIENT_BODY_TIMEOUT: body timeout.
* CLIENT_HEADER_TIMEOUT: header timeout.
* CLIENT_MAX_BODY_SIZE: maximum request body size.
* WHITE_LIST: on or off, turn on white_list feature if on, default off.
* WHITE_LIST_IP: ip you wang put through, set it as `(172.17.0.1)|(192.168.0.25)`.

### API_PLACEHOLDER && API_GATEWAY

**note:** we suggest you call api with a full url with domain, make your api
server independently. But we need to take care of cross domain and https issues.

If your app calls api without domain, and not deploy behind a **Well
Structured** haproxy(or other forward proxy), you can turn on this option.

```sh
API_PLACEHOLDER="/api/v1"
API_GATEWAY="http://api.your.domain"
```

Then all url match `/api/v1` will redirect to `http://api.your.domain`. Please
notice that the `/api/v1` will be stripped.

In case you need more gateway, you can use another 5 entries API_GATEWAY_1 ~ API_GATEWAY_5, along with API_PLACEHOLDER_1 ~ API_PLACEHOLDER_5.

### APP_BASENAME

Suppose you have a domain

```sh
www.books.com
```

You have two apps Computer and Math, want put them under the same domain.

```sh
http://www.books.com/computer
http://www.books.com/math
```

For App computer, setting

```sh
APP_BASENAME=/computer
```

You also need to take care about this path prefix in your APP. Like react
router(3.x), it could take a prefix option. We strongly suggest to use the same
envrionment in your source code. So this image will take care of it for you. For
example, in your router.js file:

```js
import useBasename from "history/lib/useBasename";
import { browserHistory } from "react-router";

export const myHistory = useBasename(() => browserHistory)({
  basename: `/${APP_BASENAME}`
});
```

### WHITE_LIST && WHITE_LIST_IP

Turn on white list mode by setting env WHITE_LIST="on", then only allow users from ${WHITE_LIST_IP} list to visit this Web App.

## FAQ (常见问题)

### Q1: 这个项目是什么？

**A:** 这是一个 Docker 基础镜像，专门用于服务单页应用（SPA），如 React、Vue、Angular 等。它基于 Alpine Linux 的 Nginx 镜像构建，体积小（约 6MB），默认支持清晰的 URL 和 pushState 路由。

### Q2: 如何快速开始使用？

**A:** 有两种方式：

**方式一：直接运行容器**

```bash
docker run -d --name myapp -p 3000:80 -v /your/webapp:/app 36node/nginx-react
```

**方式二：使用 Dockerfile（推荐）**

```dockerfile
FROM 36node/nginx-react:latest

ENV DEBUG=off \
    ENV_PREFIX=APP_ \
    NODE_ENV=production

COPY ./dist /app
```

然后构建并运行：

```bash
docker build -t my-app .
docker run -d -p 80:80 my-app
```

### Q3: 什么是运行时环境变量（Runtime Env）？如何使用？

**A:** 运行时环境变量允许你在启动容器时动态注入环境变量到前端应用中，无需重新构建镜像。

**使用方法：**

1. 启动容器时设置环境变量：

```bash
docker run -e APP_GREETINGS="Hello World" -e APP_API_URL="https://api.example.com" -d -p 3000:80 your_image
```

1. 在前端代码中访问这些变量：

```javascript
console.log(window?._runtime_?.APP_GREETINGS)
console.log(window?._runtime_?.APP_API_URL)
```

1. 使用 `ENV_PREFIX` 控制哪些环境变量会被注入（默认只注入以指定前缀开头的变量）：

```bash
ENV_PREFIX=APP_
```

### Q4: 如何配置 API 代理/网关？

**A:** 当你的前端应用需要调用后端 API 时，可以使用 `API_PLACEHOLDER` 和 `API_GATEWAY` 配置代理。

**基本配置：**

```bash
API_PLACEHOLDER="/api/v1"
API_GATEWAY="http://api.your.domain"
```

这样所有以 `/api/v1` 开头的请求都会被代理到 `http://api.your.domain`，并且 `/api/v1` 前缀会被移除。

**多网关配置（最多支持 5 个额外网关）：**

```bash
API_PLACEHOLDER="/api/v1"
API_GATEWAY="http://api.your.domain"

API_PLACEHOLDER_1="/service/a"
API_GATEWAY_1="http://service-a.domain"

API_PLACEHOLDER_2="/service/b"
API_GATEWAY_2="http://service-b.domain"
# ... 最多到 API_PLACEHOLDER_5 和 API_GATEWAY_5
```

**注意：** 我们建议使用完整的域名 URL 调用 API，让 API 服务独立部署。只有在无法使用完整域名且没有结构良好的反向代理（如 HAProxy）时才使用此功能。

### Q5: 如何在同一个域名下部署多个应用（使用 APP_BASENAME）？

**A:** 如果你需要在同一域名下部署多个应用，可以使用 `APP_BASENAME` 配置子路径。

**示例场景：**

* 域名：`www.books.com`
* 计算机应用：`http://www.books.com/computer`
* 数学应用：`http://www.books.com/math`

**Dockerfile 配置：**

```dockerfile
FROM 36node/nginx-react:latest
ENV APP_BASENAME=/computer
COPY ./dist /app
```

**前端路由配置（React Router 3.x 示例）：**

```javascript
import useBasename from "history/lib/useBasename";
import { browserHistory } from "react-router";

export const myHistory = useBasename(() => browserHistory)({
  basename: `/${process.env.APP_BASENAME || ''}`
});
```

### Q6: 如何启用白名单功能？如何限制 IP 访问？

**A:** 可以通过设置 `WHITE_LIST` 和 `WHITE_LIST_IP` 环境变量来启用白名单功能。

**启用白名单：**

```bash
WHITE_LIST=on
WHITE_LIST_IP="(172.17.0.1)|(192.168.0.25)|(10.0.0.1)"
```

**说明：**

* `WHITE_LIST=on` 开启白名单模式
* `WHITE_LIST_IP` 设置允许访问的 IP 地址列表，使用正则表达式格式
* 只有匹配的 IP 才能访问应用
* 默认情况下白名单是关闭的（`WHITE_LIST=off`）

### Q7: 项目支持哪些环境变量？分别有什么作用？

**A:** 项目支持以下预设环境变量：

| 变量名 | 默认值 | 说明 |
|--------|--------|------|
| `BUILD` | 1997-01-01T00:00:00.000Z | 镜像构建时间 |
| `DEBUG` | off | 调试模式开关 |
| `ENV_PREFIX` | (无) | 环境变量前缀过滤 |
| `APP_VERSION` | v0.0.0 | 应用版本号 |
| `APP_WORKDIR` | /app | 应用在容器中的工作目录 |
| `APP_BASENAME` | /aSubSite | 子路径前缀 |
| `CLIENT_BODY_TIMEOUT` | 10 | 请求体超时时间（秒） |
| `CLIENT_HEADER_TIMEOUT` | 10 | 请求头超时时间（秒） |
| `CLIENT_MAX_BODY_SIZE` | 1024 | 最大请求体大小（KB） |
| `API_PLACEHOLDER` | (无) | API 路径占位符 |
| `API_GATEWAY` | (无) | API 网关地址 |
| `WHITE_LIST` | off | 白名单开关 |
| `WHITE_LIST_IP` | (172.17.0.1)\|(192.168.0.25) | 允许的 IP 列表 |

### Q8: 如何进行健康检查？健康检查返回什么信息？

**A:** 项目内置了健康检查端点 `/health`，可以通过 HTTP GET 请求访问。

**访问方式：**

```bash
curl http://localhost:80/health
```

**返回的 JSON 信息：**

```json
{
  "version": "${APP_VERSION}",
  "status": "OK",
  "build": "${BUILD}",
  "debug": "${DEBUG}"
}
```

**包含的信息：**

* `version`: 应用版本号
* `status`: 服务状态（OK 表示正常）
* `build`: 构建时间
* `debug`: 调试模式状态

### Q9: Nginx 配置有哪些优化特性？

**A:** Nginx 配置包含以下优化特性：

1. **Gzip 压缩**：自动压缩文本、CSS、JavaScript、JSON、XML、图片等多种文件类型
2. **PushState 友好**：所有不存在的路径都会重定向到 `index.html`，支持 SPA 路由
3. **静态资源缓存**：对 `/static/` 目录下的资源设置 30 天缓存
4. **安全优化**：
   * 关闭服务器版本号显示 (`server_tokens off`)
   * 配置超时时间防止慢速攻击
   * 限制请求体大小
5. **CORS 支持**：健康检查端点支持跨域访问

### Q10: 如何查看示例项目？

**A:** 项目提供了 todoMVC 示例，展示了如何使用此镜像服务 React SPA 应用。

**构建并运行示例：**

```bash
cd examples/todoMVC
docker build --build-arg VERSION=v0.4.0 -t todomvc .
docker run -d -p 8080:80 todomvc
```

**访问示例：**
打开浏览器访问 [http://localhost:8080](http://localhost:8080)

**带环境变量运行：**

```bash
docker run -e APP_GREETINGS="Welcome to TodoMVC" -d -p 3000:80 todomvc
```

### Q11: 镜像的大小和基础镜像是什么？

**A:**

* **基础镜像**：`nginx:alpine`（基于 Alpine Linux）
* **镜像大小**：约 6 MB（非常轻量）
* **优势**：Alpine Linux 是一个安全的、轻量级的 Linux 发行版，适合容器化部署

### Q12: 如果遇到问题，应该如何排查？

**A:** 常见问题排查步骤：

1. **检查容器日志**：

   ```bash
   docker logs <container_name>
   ```

2. **验证环境变量是否正确注入**：

   ```bash
   docker exec <container_name> cat /app/env-runtime.js
   ```

3. **测试健康检查端点**：

   ```bash
   curl http://localhost:80/health
   ```

4. **检查 Nginx 配置**：

   ```bash
   docker exec <container_name> cat /etc/nginx/conf.d/default.conf
   ```

5. **确认端口映射和卷挂载是否正确**

6. **检查白名单配置**（如果启用了白名单功能）

### Q13: 如何在生产环境中使用这个镜像？

**A:** 生产环境建议配置：

**Dockerfile 示例：**

```dockerfile
FROM 36node/nginx-react:latest

ENV DEBUG=off \
    ENV_PREFIX=APP_ \
    NODE_ENV=production \
    CLIENT_BODY_TIMEOUT=30 \
    CLIENT_HEADER_TIMEOUT=30 \
    CLIENT_MAX_BODY_SIZE=20480 \
    WHITE_LIST=off

ARG APP_VERSION=v1.0.0
ENV APP_VERSION=${APP_VERSION}

COPY ./dist /app
```

**推荐的生产实践：**

1. 设置合理的超时时间和请求体大小限制
2. 关闭调试模式（`DEBUG=off`）
3. 使用 `ENV_PREFIX` 限制可注入的环境变量
4. 根据需要配置 API 网关和白名单
5. 定期更新镜像以获取安全补丁
6. 使用 Docker Compose 或 Kubernetes 进行编排管理

### Q14: 是否支持 HTTPS？

**A:** 是的，镜像暴露了 80 和 443 端口。要启用 HTTPS，你需要：

1. 准备 SSL 证书文件
2. 在自定义 Nginx 配置中添加 SSL 相关配置
3. 或者在外部使用负载均衡器/反向代理（如 AWS ALB、Nginx、HAProxy）终止 SSL

### Q15: 如何贡献代码或报告问题？

**A:**

* 查看 [CHANGELOG.md](CHANGELOG.md) 了解项目变更历史
* 遵循 conventional commits 规范提交代码
* 使用 `npm run release` 生成版本发布
* 如有问题，可以在 GitHub Issues 中提交

---

## License

[MIT](LICENSE.txt)
