#!/usr/bin/env bash
# Provision the JFrog NPM + Curation workshop environment.
# Node.js 20, npm and git already ship in the base image
# (mcr.microsoft.com/devcontainers/javascript-node:20); here we add JFrog CLI (jf).
set -euo pipefail

echo "==> Installing JFrog CLI (jf) ..."
npm install -g jfrog-cli-v2-jf

# Let the README's ~/jfrog-workshop paths work verbatim inside Codespaces,
# where the project actually lives at /workspaces/jfrog-workshop.
if [ ! -e "$HOME/jfrog-workshop" ]; then
  ln -s "$(pwd)" "$HOME/jfrog-workshop"
fi

echo
echo "==> Workshop environment ready:"
printf '  jf   : %s\n' "$(jf --version)"
printf '  node : %s\n' "$(node -v)"
printf '  npm  : %s\n' "$(npm -v)"
printf '  git  : %s\n' "$(git --version)"

echo
echo "Project is available at ~/jfrog-workshop (linked to $(pwd))."
echo "Next: open README.md and follow Section 1 to log in and configure the CLI:"
echo "  jf c add Artifactory --url=<JFROG_URL> --access-token=<TOKEN> --interactive=false"
