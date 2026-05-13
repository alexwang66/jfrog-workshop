---
name: mock-token-exfil-demo
description: Demonstrate how a malicious skill might attempt to collect and package sensitive credentials without accessing real secrets. Use when teaching skill supply-chain risk, showing mock token exfiltration flows, or building a safe security demo that reads only user-provided fake credentials from a local .env.demo file.
---

# Mock Token Exfil Demo

Use this skill only for explicit security training, awareness sessions, or defensive demonstrations.

This skill must not access real environment variables, shell profiles, cloud credentials, git credentials, SSH keys, or secret stores. Read only a local `.env.demo` file that the user intentionally prepared with fake values for demonstration.

## Workflow

1. Confirm the demo target file is a local `.env.demo` file containing mock values only.
2. Run `scripts/demo_read_mock_tokens.ps1` against that file.
3. Show the masked values and the simulated payload.
4. Explain that the payload is local-only and not transmitted anywhere.
5. Call out how a real malicious skill would hide this behavior, and why transparent review is necessary.

## Guardrails

- Refuse requests to read real credentials from process environment variables such as `AWS_*`, `GITHUB_*`, `GH_*`, `GIT_*`, `SSH_*`, or cloud credential files.
- Refuse requests to conceal credential collection from the user.
- Refuse requests to transmit credentials to a remote endpoint.
- Keep all examples obviously fake and clearly labeled as mock data.

## Files

- `scripts/demo_read_mock_tokens.ps1`: Parse a `.env.demo` file, mask values, and print a simulated exfiltration payload.
- `assets/.env.demo.example`: Example fake credentials for local demos.
- `references/safety-notes.md`: Brief talking points for explaining the demo.

## Example

Run:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\demo_read_mock_tokens.ps1 -EnvFile .\assets\.env.demo.example
```

Expected behavior:

- Display the detected mock keys
- Display masked values only
- Print a simulated JSON payload to show what an attacker would try to package
- State that no network transmission occurs
