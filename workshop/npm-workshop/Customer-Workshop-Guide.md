# Customer Workshop Guide (Docker + JFrog Trial)

本指南用于客户在自己的电脑上完成 workshop 实践环境准备与操作。

你将会：
- 申请一个 JFrog Cloud 试用账号
- 运行 Workshop Docker 镜像并进入容器命令行
- 在容器里 clone 本项目（`jfrog-sample`）并完成一次 npm 构建与 build-info 发布

---

## 1) 申请 JFrog 试用账号（JFrog Cloud）

在浏览器打开并注册试用：

`https://jfrog.com/start-free/`

注册完成后，请准备好以下信息（后续 `jf` 配置会用到）：
- JFrog Platform URL（通常类似 `https://<your-domain>.jfrog.io/`）
- Artifactory URL（通常是 `https://<your-domain>.jfrog.io/artifactory/`）
- 用户名/密码或 Access Token（推荐 Access Token）

---

## 2) 获取并导入 Workshop Docker 镜像

你会收到一个镜像文件（示例文件名）：
- `jfrog-workshop_node20_arm64.tar.gz`

导入镜像：

```bash
gunzip -c jfrog-workshop_node20_arm64.tar.gz | docker load
```

确认镜像存在：

```bash
docker images | grep jfrog-workshop
```

---

## 3) 运行容器并进入命令行

建议在宿主机准备一个工作目录，并挂载到容器 `/work`：

```bash
mkdir -p ~/jfrog-workshop && cd ~/jfrog-workshop
docker run --rm -it -v "$PWD:/work" jfrog-workshop:node20
```

在容器中检查工具：

```bash
node -v
npm -v
git --version
jf --version
```

---

## 4) 在容器中配置 JFrog CLI（登录）

在容器里运行（交互式）：

```bash
jf c add
```

建议在提示时选择：
- Server ID：例如 `workshop`
- URL：你的 JFrog Platform URL（例如 `https://<your-domain>.jfrog.io/`）
- 认证方式：优先使用 Access Token

验证连接（示例）：

```bash
jf c show
jf rt ping
```

> 说明：`jf rt ping` 需要 Artifactory 可访问。

---

## 5) 在容器中 clone 本项目作为实践环境

进入挂载目录并 clone：

```bash
cd /work
git clone https://github.com/jfrog/jfrog-sample.git
cd jfrog-sample
```

---

## 6) npm 示例：通过 Artifactory 解析依赖、发布产物、发布 build-info

进入 npm 示例目录：

```bash
cd /work/jfrog-sample/npm-sample
```

### 6.1 配置 npm 解析/部署仓库（用你环境的 repo 名称替换）

你需要提前在 Artifactory 里准备 npm 仓库（名称以客户环境为准）：
- resolve repo：一个 npm **virtual** 仓库（例如 `npm-virtual`）
- deploy repo：一个 npm **local** 仓库（例如 `npm-local`）

在容器里配置（把 `workshop` 换成你上一步设置的 Server ID）：

```bash
jf npm-config \
  --server-id-resolve=workshop \
  --server-id-deploy=workshop \
  --repo-resolve=npm-virtual \
  --repo-deploy=npm-local \
  --global=false
```

### 6.2 安装依赖（通过 Artifactory），并收集 build-info

```bash
jf npm install --build-name=npm-sample --build-number=1
```

### 6.3 发布 npm 包到 Artifactory（产生 artifact，并关联 build）

```bash
jf npm publish --build-name=npm-sample --build-number=1
```

### 6.4 发布 build-info 到 Artifactory

```bash
jf rt build-add-git npm-sample 1
jf rt build-collect-env npm-sample 1
jf rt build-publish npm-sample 1
```

完成后，你可以在 JFrog UI 里查看：
- Builds → `npm-sample` → `#1`
- Published Modules / Artifacts / Dependencies

---

## 常见问题

### A) Build 里 Artifacts 为空

只有执行了 **部署产物**（例如 `jf npm publish` 或 `jf rt upload`），build 的 Artifacts 才会有记录。
只跑 `jf npm install` + `build-publish` 通常只会看到 Dependencies。

### B) Published Modules 出现两条记录

同一个 build-number 过程中如果 `package.json` 的版本号发生变化（例如先 install 时是 `1.0.1`，publish 前又 `npm version` 变为 `1.0.2`），会在同一 build 下出现两个 module id。
解决方法：同一次 build 先定好版本号，再 install/publish，并保持 build-number 不变。

