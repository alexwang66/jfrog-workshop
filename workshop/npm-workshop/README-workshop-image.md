# Workshop Docker 镜像（最小化：npm + git + JFrog CLI）

目标：提供一个**可交互登录**的 Workshop 容器环境，支持：
- `npm` 构建
- `git` 拉取 `jfrog-sample`
- `jf` 登录/配置并上传构建到 Artifactory

该镜像的定义文件在：`workshop/npm-workshop/Dockerfile.npm-jf-git`。

客户 Workshop 讲义（从申请试用账号到容器内实践）：
- `workshop/npm-workshop/Customer-Workshop-Guide.md`

## 构建镜像

> 建议在有网络的环境构建一次，然后把镜像导出给客户离线使用。

```bash
docker build -f workshop/npm-workshop/Dockerfile.npm-jf-git -t jfrog-workshop:node20 .
```

如果现场网络无法访问 Docker Hub（拉不到 `alpine:3.19`），可以改用客户/你自己的 Artifactory Docker 仓库作为基础镜像来源，例如：
```bash
docker build -f workshop/npm-workshop/Dockerfile.npm-jf-git -t jfrog-workshop:node20 \
  --build-arg BASE_IMAGE=demo.jfrogchina.com/alex-docker/alpine:3.19 .
```

如需固定 JFrog CLI 版本（可复现）：

```bash
docker build -f workshop/npm-workshop/Dockerfile.npm-jf-git -t jfrog-workshop:node20 \
  --build-arg JFROG_CLI_VERSION=2.72.3 .
```

## 检查镜像大小（确保 < 100MB）

```bash
docker images jfrog-workshop:node20
docker image inspect jfrog-workshop:node20 --format '{{.Size}}'
```

> 注：`docker images` 显示的是镜像大小（近似），`inspect` 的 `.Size` 是字节数，可用于精确判断。

当前在 Apple Silicon（`linux/arm64`）上用 `apk add nodejs npm + jf` 的组合，实测镜像约 **125MB**（`jfrog-workshop:node20`），很难压到 <100MB；若你必须严格 <100MB，通常需要用已镜像化的 `node:<version>-alpine` 作为 base（并确保能从可访问的 registry 拉取）。

## 导出/导入（给客户离线下载）

导出：
```bash
docker save jfrog-workshop:node20 | gzip > jfrog-workshop_node20.tar.gz
```

导入：
```bash
gunzip -c jfrog-workshop_node20.tar.gz | docker load
```

## 交互式进入容器

把本机目录挂载到容器 `/work`，方便保存代码与产物：

```bash
mkdir -p ~/workshop && cd ~/workshop
docker run --rm -it -v "$PWD:/work" jfrog-workshop:node20
```

如果需要拉取私有仓库（SSH），可把本机 `~/.ssh` 挂进来（只读）：
```bash
docker run --rm -it \
  -v "$PWD:/work" \
  -v "$HOME/.ssh:/home/workshop/.ssh:ro" \
  jfrog-workshop:node20
```

容器里验证工具：
```bash
node -v
npm -v
git --version
jf --version
```

## 在容器里拉取并构建 `jfrog-sample`（npm 示例）

```bash
git clone https://github.com/jfrog/jfrog-sample.git
cd jfrog-sample/npm-sample
npm ci
npm run build
```

## 在容器里配置 JFrog CLI 并上传到 Artifactory（示例）

交互式配置（推荐 workshop 现场使用）：
```bash
jf c add
```

也可以用环境变量 + 非交互方式（更适合标准化脚本/演示）：
```bash
# 在宿主机先导出，再 docker run -e 透传
export JF_URL="https://<your-artifactory-url>"
export JF_ACCESS_TOKEN="<your-token>"
docker run --rm -it -v "$PWD:/work" -e JF_URL -e JF_ACCESS_TOKEN jfrog-workshop:node20

# 容器内执行（示例 server-id=default）
jf c add default --url="$JF_URL" --access-token="$JF_ACCESS_TOKEN" --interactive=false
```

然后根据你的 Workshop 脚本执行上传（示例：npm 关联 build-info）：
```bash
# 下面命令需要你根据实际仓库名/解析器名调整
jf npm-config --server-id-resolve=default --server-id-deploy=default \
  --repo-resolve=npm-virtual --repo-deploy=npm-local

jf npm ci
jf npm publish --build-name="npm-sample" --build-number="1"
jf rt build-publish "npm-sample" "1"
```

> 说明：
> - 仓库名（`npm-virtual` / `npm-local`）请按客户环境替换。
> - 如果需要使用 Access Token，建议在 `jf c add` 时选择 token 方式，或设置 `JFROG_CLI_OFFER_CONFIG=false` 等环境变量按你的标准化流程执行。

