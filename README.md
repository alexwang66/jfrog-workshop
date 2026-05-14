# NPM + Curation 工作坊指南（客戶版）

目標：在客戶本機完成一次 **npm 建置 + 發布 build-info**，並示範 **JFrog Curation 阻擋模擬惡意版本 `axios@1.7.2` 的下載**。

---

## 0. 前置需求

- JFrog Cloud 試用帳號：`https://jfrog.com/start-free/`
- 本機需安裝：
  - JFrog CLI（`jf`）
  - Git（`git`）
  - Node.js 20.x LTS，包含 `npm`

### 安裝

- **安裝 JFrog CLI**
  - 開啟 `https://jfrog.com/getcli/`
  - 依照作業系統下載並安裝對應套件。
- **安裝 Node.js 20.x LTS**
  - 開啟 `https://nodejs.org/`，安裝 **LTS 20.x** 版本。
  - **Windows 注意事項：** 安裝時建議勾選 “Add to PATH”，安裝完成後重新開啟 PowerShell 或 CMD，再執行 `node -v`。
  - macOS 搭配 Homebrew 可選用：
    ```bash
    brew install node@20
    brew link --force --overwrite node@20
    ```

驗證工具：

```bash
jf --version
git --version
node -v
npm -v
```

---

## 1. 登入 JFrog

先登入你的 JFrog Platform 實例並產生 Access Token。

官方參考文件：

- Access Tokens：`https://docs.jfrog.com/administration/docs/access-tokens`
- JFrog CLI Configuration：`https://docs.jfrog.com/integrations/docs/configuring-the-cli`

在 JFrog Platform UI 中：

1. 開啟你的 JFrog Platform 位址，例如 `https://<your-jfrog-domain>`。
2. 進入 Administration -> Security -> Access Tokens。
3. 點擊 Generate Token，為目前使用者建立 Access Token。
4. 複製並妥善保存 token，後續 JFrog CLI 會使用它。

Access Token 頁面 URL 格式：

```text
https://<your-jfrog-domain>/ui/admin/configuration/security/access_tokens
```

`<your-jfrog-domain>` 是你的 JFrog Platform 網域，例如 `company.jfrog.io`。

使用一條命令設定 JFrog CLI。Server ID 固定為 `Artifactory`。

Windows PowerShell：

```powershell
$env:JFROG_URL = "https://<your-jfrog-domain>"
$env:JFROG_ACCESS_TOKEN = "<your-access-token>"

jf c add Artifactory --url=$env:JFROG_URL --access-token=$env:JFROG_ACCESS_TOKEN --interactive=false
```

macOS / Linux：

```bash
JFROG_URL="https://<your-jfrog-domain>"
JFROG_ACCESS_TOKEN="<your-access-token>"

jf c add Artifactory --url="$JFROG_URL" --access-token="$JFROG_ACCESS_TOKEN" --interactive=false
```

驗證設定：

```bash
jf c show
jf rt ping
```

後續所有命令都使用 Server ID `Artifactory`。如果看到 `Server ID 'Artifactory' does not exist`，代表 CLI 設定沒有成功建立，請重新執行 `jf c add Artifactory ...`。

---

## 2. 複製工作坊 Repository

```bash
cd ~
git clone https://github.com/alexwang66/jfrog-workshop.git
cd jfrog-workshop
```

---

## 3. 建立工作坊 Repository

在 `automation` 目錄執行建立 repository 的腳本。

每位學員使用自己的英文名作為 `STUDENT_ID` 前綴，以避免多人共用 lab 時互相覆蓋 repository、remote cache、build-info 或 Curation policy。

命名規則：

- 僅使用小寫英文字母、數字與連字符 `-`
- 長度 3-20 個字元
- 不使用空格、中文或特殊符號
- 如果英文名重複，請加上姓氏或數字，例如 `alex-wang`、`alex2`

範例：如果學員英文名是 Alex，請使用 `alex`。

Windows PowerShell：

```powershell
cd ~/jfrog-workshop/automation
$env:STUDENT_ID = "alex"
.\create-repo.ps1 -StudentId $env:STUDENT_ID
```

如果 PowerShell 執行原則阻擋腳本，可在目前終端機暫時允許腳本後重試：

```powershell
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
.\create-repo.ps1 -StudentId $env:STUDENT_ID
```

macOS / Linux：

```bash
cd ~/jfrog-workshop/automation
export STUDENT_ID="alex"
chmod +x ./create-repo.sh
./create-repo.sh "$STUDENT_ID" all
```

腳本會建立以下 npm repositories：

- Resolve repository：`<student-id>-npm-virtual`（virtual）
- Remote repository：`<student-id>-npm-remote`（remote，指向 npmjs）
- Deploy repository：`<student-id>-npm-dev-local`（local）
- QA repository：`<student-id>-npm-qa-local`（local）
- Prod repository：`<student-id>-npm-prod-local`（local）

如需清理某位學員的 repository，使用相同的 `STUDENT_ID` 執行刪除腳本：

Windows PowerShell：

```powershell
cd ~/jfrog-workshop/automation
$env:STUDENT_ID = "alex"
.\delete-repo.ps1 -StudentId $env:STUDENT_ID
```

macOS / Linux：

```bash
cd ~/jfrog-workshop/automation
export STUDENT_ID="alex"
./delete-repo.sh "$STUDENT_ID" all
```

---

## 4. NPM 建置、發布與 Build-Info

進入範例專案目錄。

Windows PowerShell：

```powershell
cd ~/jfrog-workshop/npm-sample
$env:STUDENT_ID = "alex"
Get-Content .\package.json
```

macOS / Linux：

```bash
cd ~/jfrog-workshop/npm-sample
export STUDENT_ID="alex"
cat ./package.json
```

所有 `npm` 與 `jf npm ...` 命令都必須在 `npm-sample` 目錄中執行。不要在 `automation` 目錄中執行這些命令；`automation` 只用於建立 JFrog repositories。

設定 npm 解析與部署：

Windows PowerShell：

```powershell
jf npm-config `
  --server-id-resolve=Artifactory `
  --server-id-deploy=Artifactory `
  --repo-resolve="$($env:STUDENT_ID)-npm-virtual" `
  --repo-deploy="$($env:STUDENT_ID)-npm-dev-local" `
  --global=false
```

macOS / Linux：

```bash
jf npm-config \
  --server-id-resolve=Artifactory \
  --server-id-deploy=Artifactory \
  --repo-resolve="${STUDENT_ID}-npm-virtual" \
  --repo-deploy="${STUDENT_ID}-npm-dev-local" \
  --global=false
```

清理本機安裝結果、`package-lock.json` 與 npm 快取，確保依賴重新透過 JFrog Artifactory 解析。

Windows PowerShell：

```powershell
Remove-Item -Recurse -Force node_modules, package-lock.json -ErrorAction SilentlyContinue
npm cache clean --force
Test-Path .\package-lock.json
```

`Test-Path .\package-lock.json` 應回傳 `False`，表示 lock 檔案已刪除。

macOS / Linux：

```bash
rm -rf node_modules package-lock.json
npm cache clean --force
test ! -f ./package-lock.json && echo "package-lock.json removed"
```

安裝、發布套件並發布 build-info：

Windows PowerShell：

```powershell
$env:BUILD_NAME = "$($env:STUDENT_ID)-npm-sample"
$env:BUILD_NUMBER = "1"

jf npm install --build-name=$env:BUILD_NAME --build-number=$env:BUILD_NUMBER
jf npm publish --build-name=$env:BUILD_NAME --build-number=$env:BUILD_NUMBER

jf rt build-add-git $env:BUILD_NAME $env:BUILD_NUMBER
jf rt build-collect-env $env:BUILD_NAME $env:BUILD_NUMBER
jf rt build-publish $env:BUILD_NAME $env:BUILD_NUMBER
```

macOS / Linux：

```bash
BUILD_NAME="${STUDENT_ID}-npm-sample"
BUILD_NUMBER=1

jf npm install --build-name="$BUILD_NAME" --build-number="$BUILD_NUMBER"
jf npm publish --build-name="$BUILD_NAME" --build-number="$BUILD_NUMBER"

jf rt build-add-git "$BUILD_NAME" "$BUILD_NUMBER"
jf rt build-collect-env "$BUILD_NAME" "$BUILD_NUMBER"
jf rt build-publish "$BUILD_NAME" "$BUILD_NUMBER"
```

在 UI 中驗證：

- Artifactory -> Builds -> `<student-id>-npm-sample` -> `#1`

---

## 5. Curation 示範：阻擋 `axios@1.7.2`

本工作坊 **將 `axios@1.7.2` 視為模擬惡意套件版本**。目標是讓 `npm install` 透過 JFrog Curation 解析到該版本時被阻擋。

### 5.1 啟用 Remote Repository 的 Curation

先確認學員自己的 remote repository 已啟用 Curation，後續 policy 才能對下載請求生效。

- 進入 Administration -> Curation -> Remote Repositories，或依你的 UI 版本進入類似頁面。
- 找到 `<student-id>-npm-remote`，確認 Curation 已啟用。

示例：

![Enable Curation Remote Repository](./workshop/images/current-curation-remote.svg)

不同 JFrog Platform 版本的 UI 標籤可能略有差異，請以你的實例畫面為準。

### 5.2 將範例專案切換到被阻擋版本

為了觸發 Curation 阻擋，先直接修改 `~/jfrog-workshop/npm-sample/package.json`，將範例專案的 `axios` 依賴切換到本 Lab 指定的模擬風險版本。

Windows PowerShell：

```powershell
cd ~/jfrog-workshop/npm-sample
notepad .\package.json
Get-Content .\package.json
```

macOS / Linux：

```bash
cd ~/jfrog-workshop/npm-sample
nano package.json
cat package.json
```

確認 `package.json` 中存在以下內容：

```json
{
  "dependencies": {
    "axios": "1.7.2"
  }
}
```

接著在重新安裝前清理專案。必須刪除 `package-lock.json`；否則 npm 可能判斷依賴樹已滿足，導致 Curation 阻擋效果不易觀察。

Windows PowerShell：

```powershell
cd ~/jfrog-workshop/npm-sample
Remove-Item -Recurse -Force node_modules, package-lock.json -ErrorAction SilentlyContinue
npm cache clean --force
Test-Path .\package-lock.json
```

`Test-Path .\package-lock.json` 應回傳 `False`。

macOS / Linux：

```bash
cd ~/jfrog-workshop/npm-sample
rm -rf node_modules package-lock.json
npm cache clean --force
test ! -f ./package-lock.json && echo "package-lock.json removed"
```

### 5.3 在 JFrog UI 建立 Curation Policy

先建立 Custom Condition，再將它用於 Curation Policy。

#### 5.3.1 建立 Custom Condition

官方參考文件：`https://docs.jfrog.com/security/docs/create-custom-conditions`

在 JFrog UI 中：

- 進入 Administration -> Curation Settings -> **Conditions**。
- 點擊 **Create Condition**。
- 選擇 **Block Specific Package Versions** 範本。
- 設定：
  - Condition name：`<student-id>-axios-1.7.2`
  - Package type：`npm`
  - Package：`axios`
  - Version：`1.7.2`
- 儲存 condition。

示例：

![Create Curation Condition](./workshop/images/current-curation-condition.svg)

#### 5.3.2 建立 Policy 並套用到 NPM Remote Repository

在 JFrog UI 中：

- 進入 Administration -> Curation -> **Policies Management**。
- 建立 policy：
  - Policy name：`<student-id>-npm-curation-policy`
  - Scope：選擇 **Specific remote repositories**，並選取 `<student-id>-npm-remote`。
  - Condition：選擇剛建立的 `axios 1.7.2` custom condition。
  - Action：**Block**。
- 儲存 policy。

示例：

![Create Curation Policy](./workshop/images/current-curation-policy.svg)

### 5.4 從 Artifactory Remote Cache 刪除已快取的 `axios`

如果 `axios@1.7.2` 在建立 Curation policy 前已被下載，Artifactory 可能已將它快取到 remote cache repository。重新安裝前需先刪除該快取套件。

官方參考文件：

- Remote Repositories：`https://docs.jfrog.com/artifactory/docs/remote-repositories`
- Managing Artifacts：`https://docs.jfrog.com/artifactory/docs/managing-artifacts`

在 JFrog UI 中：

1. 進入 Artifactory -> Artifacts。
2. 開啟 remote cache repository：`<student-id>-npm-remote-cache`。
3. 找到 `axios`。
4. 右鍵點擊 `axios`，選擇 Delete / Delete Content。
5. 確認刪除。

示例：

![Delete Axios From Remote Cache](./workshop/images/current-remote-cache-delete.svg)

### 5.5 重新執行 Install 並觀察阻擋

Windows PowerShell：

```powershell
cd ~/jfrog-workshop/npm-sample
$env:STUDENT_ID = "alex"
Remove-Item -Recurse -Force node_modules, package-lock.json -ErrorAction SilentlyContinue
npm cache clean --force

$env:BUILD_NAME = "$($env:STUDENT_ID)-npm-curation"
$env:BUILD_NUMBER = "2"

jf npm install --build-name=$env:BUILD_NAME --build-number=$env:BUILD_NUMBER
jf rt build-add-git $env:BUILD_NAME $env:BUILD_NUMBER
jf rt build-collect-env $env:BUILD_NAME $env:BUILD_NUMBER
jf rt build-publish $env:BUILD_NAME $env:BUILD_NUMBER
```

macOS / Linux：

```bash
cd ~/jfrog-workshop/npm-sample
export STUDENT_ID="alex"
rm -rf node_modules package-lock.json
npm cache clean --force

BUILD_NAME="${STUDENT_ID}-npm-curation"
BUILD_NUMBER=2

jf npm install --build-name="$BUILD_NAME" --build-number="$BUILD_NUMBER"
jf rt build-add-git "$BUILD_NAME" "$BUILD_NUMBER"
jf rt build-collect-env "$BUILD_NAME" "$BUILD_NUMBER"
jf rt build-publish "$BUILD_NAME" "$BUILD_NUMBER"
```

預期結果：

- CLI 輸出顯示某個套件版本被阻擋，具體為 `axios@1.7.2`。
- 安裝失敗，或依 policy action 與設定被替換為允許版本。

CLI 被阻擋輸出示例：


![Curation CLI Blocked](./workshop/images/current-cli-blocked.svg)

如果輸出類似 `added 28 packages`，表示 npm 已成功安裝依賴，Curation 沒有阻擋本次下載。請檢查：

- Policy 是否已儲存並啟用。
- Policy action 是否為 **Block**，而不是 Dry Run 或僅 audit。
- Policy scope 是否包含 `<student-id>-npm-remote`。
- Administration -> Curation -> Remote Repositories 是否顯示 `<student-id>-npm-remote` 為 Connected / Curated。
- `<student-id>-npm-remote` 是否已啟用 Xray indexing。官方 On-Demand Curation 文件建議同時確認 remote repository 已啟用 Curation 與 Xray indexing。
- Custom condition 是否精確匹配 Package type `npm`、Package `axios`、Version `1.7.2`。
- 本機 `node_modules` 與 `package-lock.json` 是否已刪除，並已執行 `npm cache clean --force`。
- Artifactory -> Artifacts -> `<student-id>-npm-remote-cache` 中是否已不再包含 `axios`。
- Curation audit/events 是否出現本次下載事件。若沒有事件，通常表示該 repository 尚未由 Curation 接管。若事件顯示 No Policy Violation，通常表示 policy condition、scope 或 action 未匹配。

Curation audit event 示例：

![Curation Audit Blocked](./workshop/images/current-curation-audit.svg)

### 5.6 在 Catalog 中選擇可用版本並重新構建

阻擋效果確認後，回到 JFrog Catalog 查找 `axios` 的最新版本，確認該版本是否可下載。

官方參考文件：

- Catalog：`https://docs.jfrog.com/security/docs/catalog`
- Use npm with JFrog CLI：`https://docs.jfrog.com/artifactory/docs/use-npm-with-jfrog-cli`

在 JFrog UI 中：

1. 進入 Catalog -> Explore。
2. 搜尋 `axios`。
3. 選擇最新版本 `1.16.1`。
4. 確認頁面顯示 **Approved for downloading**。

示例：

![Catalog Axios Approved](./workshop/images/current-catalog-axios-approved.svg)

接著直接修改 `package.json`，將專案修復到允許版本並更新應用版本號。

Windows PowerShell：

```powershell
cd ~/jfrog-workshop/npm-sample
$env:STUDENT_ID = "alex"

notepad .\package.json
Get-Content .\package.json
```

macOS / Linux：

```bash
cd ~/jfrog-workshop/npm-sample
export STUDENT_ID="alex"

nano package.json
cat package.json
```

確認 `package.json` 中至少包含以下內容：

```json
{
  "version": "1.0.4",
  "dependencies": {
    "axios": "1.16.1"
  }
}
```

清理本機 npm 狀態後重新構建並上傳 build-info。

Windows PowerShell：

```powershell
cd ~/jfrog-workshop/npm-sample
$env:STUDENT_ID = "alex"

Remove-Item -Recurse -Force node_modules, package-lock.json -ErrorAction SilentlyContinue
npm cache clean --force

$env:BUILD_NAME = "$($env:STUDENT_ID)-npm-remediation"
$env:BUILD_NUMBER = "3"

jf npm install --build-name=$env:BUILD_NAME --build-number=$env:BUILD_NUMBER
jf rt build-add-git $env:BUILD_NAME $env:BUILD_NUMBER
jf rt build-collect-env $env:BUILD_NAME $env:BUILD_NUMBER
jf rt build-publish $env:BUILD_NAME $env:BUILD_NUMBER
```

macOS / Linux：

```bash
cd ~/jfrog-workshop/npm-sample
export STUDENT_ID="alex"

rm -rf node_modules package-lock.json
npm cache clean --force

BUILD_NAME="${STUDENT_ID}-npm-remediation"
BUILD_NUMBER=3

jf npm install --build-name="$BUILD_NAME" --build-number="$BUILD_NUMBER"
jf rt build-add-git "$BUILD_NAME" "$BUILD_NUMBER"
jf rt build-collect-env "$BUILD_NAME" "$BUILD_NUMBER"
jf rt build-publish "$BUILD_NAME" "$BUILD_NUMBER"
```

在 UI 中驗證：

- Artifactory -> Builds -> `<student-id>-npm-remediation` -> `#3`
- Build-info 中的 dependencies 應顯示已使用 `axios@1.16.1`。
