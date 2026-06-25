# NPM + Curation Workshop Guide (Customer)

Goal: Complete an **npm build + build-info publication** on a customer machine, and demonstrate how **JFrog Curation blocks the download of a simulated malicious version, `axios@1.7.2`**.

## Workshop Flow

0. **Prerequisites** — install and verify `jf`, `git`, `node`, `npm`
1. **Log In To JFrog** — generate an Access Token, configure the JFrog CLI
2. **Clone The Workshop Repository** — clone the sample project to your machine
3. **Create The Workshop Repositories** — create your own set of npm repositories with the script
4. **NPM Build, Publish, And Build-Info** — first build and push build-info (`#1`)
5. **Curation Demo** — introduce the simulated-malicious `axios@1.7.2`, block it with Curation, then switch back to a safe version

---

## 0. Prerequisites

Before you start, make sure the following tools are installed and runnable on your machine.

- JFrog Cloud trial account: `https://jfrog.com/start-free/`
- Required local tools:
  - VS Code or any code editor (recommended, for opening the project and running the integrated terminal)
  - JFrog CLI (`jf`)
  - Git (`git`)
  - Node.js 20.x LTS, including `npm`

### Installation

- **Install JFrog CLI**
  - Open `https://jfrog.com/getcli/`
  - Download and install the package for your operating system.

- **Install Node.js 20.x LTS**
  - Open `https://nodejs.org/` and install the **LTS 20.x** package.
  - **Windows note:** select “Add to PATH” during installation, then open a new PowerShell or CMD window before running `node -v`.
  - Optional for macOS with Homebrew:
    ```bash
    brew install node@20
    brew link --force --overwrite node@20
    ```

Verify the tools:

```bash
jf --version
git --version
node -v
npm -v
```

> ✅ Checkpoint 1: all four `--version` commands print a version, so the tools are ready.

---

## 1. Log In To JFrog

With the tools ready, log in to the platform: first sign in to the JFrog Platform UI with your **lab account**, then generate an Access Token in the UI, and finally use it to configure the JFrog CLI.

### 1.1 Find And Log In To Your Lab Account

Every attendee has a lab account derived from their **seat**.

**Seat map:**

![Lab account seat map](workshop/lab-account-seatmap.png)

- The screen is at the front; the instructor's podium is at the front-right.
- There are two table types: **slim blue tables = 2 seats (S1–S2)**; **wide tables = 4 seats (S1–S4)**.
- Each small square under a table is a seat; the number on it is your **seat number**.

**Find your account in 3 steps:**

| Step | Action |
|:---:|---|
| **1** | Find your **table number** `T1` – `T20` on the seat map |
| **2** | Check the table sign for your **seat number** `S1` / `S2` … (a 2-seat table only has S1, S2) |
| **3** | Build your account: **`labuser-t<table>-s<seat>`** |

> **Example:** seated at **table 4, seat 3** → your account is `labuser-t4-s3`.

**Login info:**

| Item | Value |
|---|---|
| **Platform URL** | `https://<your-jfrog-domain>` |
| **Username** | `labuser-t<table>-s<seat>` |
| **Password** | Shared password (announced on-site by the instructor) |

Login steps:

1. Open the platform URL `https://<your-jfrog-domain>` in a browser.
2. On the login page, enter your **username** and the **shared password** (announced on-site).
3. Click **Log In** to enter the JFrog platform.

> ⚠️ **Do not change the password**, or later logins / instructor assistance may not match.
>
> Can't log in? 1) Check the account is all-lowercase with the right table/seat number; 2) Check the password is entered correctly; 3) Still stuck — **raise your hand for the instructor**.

### 1.2 Generate An Access Token And Configure The CLI

After logging in, connect the JFrog CLI to your JFrog Platform instance: generate an Access Token in the UI, then use it to configure the CLI.

Generate an Access Token in the JFrog Platform UI:

1. From the left navigation, go to: **Administration → User Management → Access Tokens**.
2. Click **Generate Token**.
3. In the dialog, **just click Generate** — no extra configuration is needed.
4. Copy and store the generated token securely.
5. Put the token into the `JFROG_ACCESS_TOKEN` environment variable in your terminal below, for use by JFrog CLI.

Configure JFrog CLI with one command. The Server ID is fixed as `Artifactory`.

<img src="./workshop/images/microsoft-logo.svg" width="14" alt="Windows"/> Windows PowerShell:

```powershell
$env:JFROG_URL = "https://<your-jfrog-domain>"
$env:JFROG_ACCESS_TOKEN = "<your-access-token>"

jf c add Artifactory --url=$env:JFROG_URL --access-token=$env:JFROG_ACCESS_TOKEN --interactive=false
```

🐧 macOS / Linux:

```bash
JFROG_URL="https://<your-jfrog-domain>"
JFROG_ACCESS_TOKEN="<your-access-token>"

jf c add Artifactory --url="$JFROG_URL" --access-token="$JFROG_ACCESS_TOKEN" --interactive=false
```

Verify the configuration:

```bash
jf c use Artifactory
jf c show
jf rt ping
```

All later commands use the Server ID `Artifactory`. If you see `Server ID 'Artifactory' does not exist`, the CLI configuration was not created successfully. Run the `jf c add Artifactory ...` command again.

> ✅ Checkpoint 2: `jf rt ping` returns `OK`, and `jf c show` lists the `Artifactory` server.

---

## 2. Clone The Workshop Repository

With the CLI connected, clone the workshop sample project to your machine.

```bash
cd ~
# If ~/jfrog-workshop already exists (e.g. you cloned it before), skip the clone and just enter it
# --depth 1 makes a shallow clone (latest version only, no history) — smaller and faster to download
git clone --depth 1 https://github.com/alexwang66/jfrog-workshop.git
cd ~/jfrog-workshop
```

> ✅ Checkpoint 3: the `~/jfrog-workshop` directory exists and contains `npm-sample/` and `automation/`.
>
> ℹ️ All later `cd` commands use **absolute paths** (e.g. `cd ~/jfrog-workshop/automation`), so you can copy-paste them from any directory without errors — there is **no** need to manually `cd jfrog-workshop` again.

---

## 3. Create The Workshop Repositories

With the project cloned, use the script in the `automation` directory to create your own set of npm repositories in Artifactory.

Each student should use their own user id (login account) as `STUDENT_ID`. This value becomes the repository prefix and prevents students from overwriting each other in a shared lab.

Example: if your user id is `labuser-t4-s3`, set `STUDENT_ID` to `labuser-t4-s3`, then run the creation script below.

<img src="./workshop/images/microsoft-logo.svg" width="14" alt="Windows"/> Windows PowerShell:

```powershell
cd ~/jfrog-workshop/automation
$env:STUDENT_ID = "labuser-t4-s3"
.\create-repo.ps1 -StudentId $env:STUDENT_ID
```

If PowerShell blocks script execution, temporarily allow scripts in the current terminal and retry:

```powershell
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
.\create-repo.ps1 -StudentId $env:STUDENT_ID
```

🐧 macOS / Linux:

```bash
cd ~/jfrog-workshop/automation
export STUDENT_ID="labuser-t4-s3"
chmod +x ./create-repo.sh
./create-repo.sh "$STUDENT_ID" all
```

The scripts create these npm repositories:
- Resolve repository: `<student-id>-npm-virtual` (virtual)
- Remote repository: `<student-id>-npm-remote` (remote, pointing to npmjs)
- Deploy repository: `<student-id>-npm-dev-local` (local)

In Artifactory, open `https://<your-jfrog-domain>/ui/admin/repositories` to view the repositories you just created. Select **All Repositories** and search for your student-id in the search box on the right.

![Created repositories](./workshop/images/repos-created.png)

> ✅ Checkpoint 4: in All Repositories you can find 3 repos prefixed with your student-id (`-npm-virtual` / `-npm-remote` / `-npm-dev-local`).

---

## 4. NPM Build, Publish, And Build-Info

With the repositories ready, complete the first npm build on your machine and push the build-info to Artifactory.

This workshop **treats `axios@1.7.2` as a simulated malicious package version**. The goal is to make `npm install` fail when it tries to resolve that version through JFrog Curation.

Enter the sample project directory. The path below uses `~/jfrog-workshop/npm-sample` as an example; **if you cloned the project elsewhere (e.g. Codespaces or a custom directory), change it to your own `npm-sample` path**. You only need to `cd` once — the npm / jf commands that follow all assume you are already in this directory, so you don't need to `cd` again each time.

<img src="./workshop/images/microsoft-logo.svg" width="14" alt="Windows"/> Windows PowerShell:

```powershell
cd ~/jfrog-workshop/npm-sample
Get-Content .\package.json
```

🐧 macOS / Linux:

```bash
cd ~/jfrog-workshop/npm-sample
cat ./package.json
```

All `npm` and `jf npm ...` commands must be executed from the `npm-sample` directory. Do not run them from the `automation` directory. The `automation` directory is only used to create JFrog repositories.

Configure npm resolution and deployment:

<img src="./workshop/images/microsoft-logo.svg" width="14" alt="Windows"/> Windows PowerShell:

```powershell
jf npm-config `
  --server-id-resolve=Artifactory `
  --server-id-deploy=Artifactory `
  --repo-resolve="$($env:STUDENT_ID)-npm-virtual" `
  --repo-deploy="$($env:STUDENT_ID)-npm-dev-local" `
  --global=false
```

🐧 macOS / Linux:

```bash
jf npm-config \
  --server-id-resolve=Artifactory \
  --server-id-deploy=Artifactory \
  --repo-resolve="${STUDENT_ID}-npm-virtual" \
  --repo-deploy="${STUDENT_ID}-npm-dev-local" \
  --global=false
```

Install, publish, and publish build-info:

<img src="./workshop/images/microsoft-logo.svg" width="14" alt="Windows"/> Windows PowerShell:

```powershell
$env:BUILD_NAME = "$($env:STUDENT_ID)-npm-sample"
$env:BUILD_NUMBER = "1"

jf npm install --build-name=$env:BUILD_NAME --build-number=$env:BUILD_NUMBER
jf npm publish --build-name=$env:BUILD_NAME --build-number=$env:BUILD_NUMBER

jf rt build-add-git $env:BUILD_NAME $env:BUILD_NUMBER
jf rt build-collect-env $env:BUILD_NAME $env:BUILD_NUMBER
jf rt build-publish $env:BUILD_NAME $env:BUILD_NUMBER
```

🐧 macOS / Linux:

```bash
BUILD_NAME="${STUDENT_ID}-npm-sample"
BUILD_NUMBER=1

jf npm install --build-name="$BUILD_NAME" --build-number="$BUILD_NUMBER"
jf npm publish --build-name="$BUILD_NAME" --build-number="$BUILD_NUMBER"

jf rt build-add-git "$BUILD_NAME" "$BUILD_NUMBER"
jf rt build-collect-env "$BUILD_NAME" "$BUILD_NUMBER"
jf rt build-publish "$BUILD_NAME" "$BUILD_NUMBER"
```

Verify in the UI:
- Artifactory -> Builds -> `<student-id>-npm-sample` -> `#1`

![Build #1 build-info](./workshop/images/build-info-1.png)

> ✅ Checkpoint 5: `#1` appears under Builds, and the build-info dependencies include `axios@1.7.2`.

---

## 5. Curation Demo: Block `axios@1.7.2`

With the first build-info in place, here is the core of the workshop: create a Curation Policy and Condition to block `axios@1.7.2` at the download source, then switch back to a safe version and rebuild.

### 5.1  Create A Curation Policy To Block axios@1.7.2

> ⚠️ When multiple people share the same platform, Policy and Condition names must be unique. Add your own student-id to both the Policy name and the Condition name (e.g. `block-axios-172-<student-id>`). The Condition name must not contain `.`, so use `172` instead of `1.7.2`.

- Step 1
![Create Curation Policy (step 1)](./workshop/images/curation-policy-step1.png)
- Step 2
![Remote repository with Curation enabled](./workshop/images/curation-remote-enabled.png)

- Step 3, create a new Condition
![New Curation Condition](./workshop/images/curation-condition-new.png)

![Curation Condition configuration](./workshop/images/curation-condition-config.png)

- Step 4, Click Next
- Step 5, Select **Block** and Save the Policy; make sure you check the **Enforce policy on cached packages** option.

![Select Block and Save Policy](./workshop/images/curation-policy-save.png)

### 5.2 Re-run Install And Observe The Block

<img src="./workshop/images/microsoft-logo.svg" width="14" alt="Windows"/> Windows PowerShell:

```powershell
Remove-Item -Recurse -Force node_modules, package-lock.json -ErrorAction SilentlyContinue
npm cache clean --force

$env:BUILD_NAME = "$($env:STUDENT_ID)-npm-sample"
$env:BUILD_NUMBER = "2"

jf npm install --build-name=$env:BUILD_NAME --build-number=$env:BUILD_NUMBER
```

🐧 macOS / Linux:

```bash
rm -rf node_modules package-lock.json
npm cache clean --force

BUILD_NAME="${STUDENT_ID}-npm-sample"
BUILD_NUMBER=2

jf npm install --build-name="$BUILD_NAME" --build-number="$BUILD_NUMBER"
```

Expected result:
- CLI output shows that a package version was blocked, specifically `axios@1.7.2`.
- Installation fails or is replaced by an allowed version, depending on the policy action and configuration.

Example blocked CLI output:

```text
21:47:28 [Error] error while running 'C:\Program Files\nodejs\npm.cmd install': exit status 1
npm error config prefix cannot be changed from project config: D:\jfrog\code\jfrog-devopsdays-workshop\npm-sample\.npmrc.
npm notice package axios:1.7.2 download was blocked by jfrog packages curation service due to the following policies violated {block-axios172,block-axios-172,This package version is part of a pre-defined banned list.}
```

![Curation CLI Blocked](./workshop/images/current-cli-blocked.svg)

If the output is similar to `added 28 packages`, npm installed the dependencies successfully and Curation did not block this download. Check:
- The policy is saved and enabled.
- The policy action is **Block**, not Dry Run or audit-only.
- The policy scope includes `<student-id>-npm-remote`.
- Administration -> Curation -> Remote Repositories shows `<student-id>-npm-remote` as Connected / Curated.
- `<student-id>-npm-remote` has Xray indexing enabled. The official On-Demand Curation documentation recommends confirming both Curation and Xray indexing for the remote repository.
- The custom condition exactly matches Package type `npm`, Package `axios`, Version `1.7.2`.
- Local `node_modules` and `package-lock.json` were deleted, and `npm cache clean --force` was run.
- Artifactory -> Artifacts -> `<student-id>-npm-remote-cache` no longer contains `axios`.
- Curation audit/events show this download attempt. If no event is shown, the repository is usually not handled by Curation. If the event says No Policy Violation, the policy condition, scope, or action usually did not match.

Curation audit event example:

![Curation Audit Blocked](./workshop/images/current-curation-audit.svg)

### 5.3 Find An Approved Version In Catalog And Rebuild

After confirming the block, go back to JFrog Catalog, find the latest `axios` version, and verify that it is allowed for download.

Official references:
- Catalog: `https://docs.jfrog.com/security/docs/catalog`
- Use npm with JFrog CLI: `https://docs.jfrog.com/artifactory/docs/use-npm-with-jfrog-cli`

In the JFrog UI:
1. Go to Catalog -> Explore.
2. Search for `axios`.
3. Select the latest version, `1.16.1`.
4. Confirm that the page shows **Approved for downloading**.

Example:

![Catalog Axios Approved](./workshop/images/current-catalog-axios-approved.svg)

Then directly edit `package.json` to remediate the project to the approved version and update the package version.

<img src="./workshop/images/microsoft-logo.svg" width="14" alt="Windows"/> Windows PowerShell:

```powershell
notepad .\package.json
Get-Content .\package.json
```

🐧 macOS / Linux:

```bash
nano package.json
cat package.json
```

Confirm that `package.json` contains at least this content:

```json
{
  "version": "1.0.4",
  "dependencies": {
    "axios": "1.16.1"
  }
}
```

Clean the local npm state, rebuild, and publish build-info.

<img src="./workshop/images/microsoft-logo.svg" width="14" alt="Windows"/> Windows PowerShell:

```powershell
Remove-Item -Recurse -Force node_modules, package-lock.json -ErrorAction SilentlyContinue
npm cache clean --force

$env:BUILD_NAME = "$($env:STUDENT_ID)-npm-sample"
$env:BUILD_NUMBER = "3"

jf npm install --build-name=$env:BUILD_NAME --build-number=$env:BUILD_NUMBER
jf npm publish --build-name=$env:BUILD_NAME --build-number=$env:BUILD_NUMBER
jf rt build-add-git $env:BUILD_NAME $env:BUILD_NUMBER
jf rt build-collect-env $env:BUILD_NAME $env:BUILD_NUMBER
jf rt build-publish $env:BUILD_NAME $env:BUILD_NUMBER
```

🐧 macOS / Linux:

```bash
rm -rf node_modules package-lock.json
npm cache clean --force

BUILD_NAME="${STUDENT_ID}-npm-sample"
BUILD_NUMBER=3

jf npm install --build-name="$BUILD_NAME" --build-number="$BUILD_NUMBER"
jf npm publish --build-name="$BUILD_NAME" --build-number="$BUILD_NUMBER"
jf rt build-add-git "$BUILD_NAME" "$BUILD_NUMBER"
jf rt build-collect-env "$BUILD_NAME" "$BUILD_NUMBER"
jf rt build-publish "$BUILD_NAME" "$BUILD_NUMBER"
```

Verify in the UI:
- Artifactory -> Builds -> `<student-id>-npm-sample` -> `#3`
- The build-info dependencies should show `axios@1.16.1`.

> ✅ Checkpoint 6: `#2` triggered the Curation block (or shows `axios 1.7.2` vulnerabilities in Xray), and `#3` rebuilt successfully using `axios@1.16.1`. The Curation flow is complete.

---

## Appendix: Clean Up Repositories

To clean up one student's repositories, run the delete script with the same `STUDENT_ID`:

<img src="./workshop/images/microsoft-logo.svg" width="14" alt="Windows"/> Windows PowerShell:

```powershell
cd ~/jfrog-workshop/automation
$env:STUDENT_ID = "labuser-t4-s3"
.\delete-repo.ps1 -StudentId $env:STUDENT_ID
```

🐧 macOS / Linux:

```bash
cd ~/jfrog-workshop/automation
export STUDENT_ID="labuser-t4-s3"
chmod +x ./delete-repo.sh
./delete-repo.sh "$STUDENT_ID" all
```

> Note: `delete-repo.sh ... all` removes the 3 npm repositories and also deletes this workshop's build-info (`<student-id>-npm-sample`).
