#!/usr/bin/env bash
set -e  # exit on error

REPO="https://github.com/microsoft/vscode.git"
TARGET_DIR="$HOME/personal/vscode"

echo "Cloning latest VS Code release..."
git clone --branch $(git ls-remote --tags "$REPO"  \
  | grep -o 'refs/tags/[0-9.]*$' \
  | sort -V \
  | tail -n1 \
  | sed 's/refs\/tags\///') \
  --single-branch "$REPO" "$TARGET_DIR"

echo "Installing dependencies..."
sudo pacman -S --needed base-devel git python libx11 libxkbfile libsecret krb5

# Sanity check
echo "Checking toolchain..."
gcc --version
make --version
pkg-config --version
python --version

echo "Installing NVM..."
export NVM_DIR="$HOME/.nvm"
if [ ! -d "$NVM_DIR" ]; then
  curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/master/install.sh | bash
fi
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

echo "Installing Node.js (LTS) and Yarn..."
nvm install --lts
nvm use --lts

export PATH="$(npm bin -g):$PATH"

node -v
npm -v

npm install -g yarn
yarn -v

cd "$TARGET_DIR"

echo "Building VS Code..."
yarn
yarn compile
yarn gulp vscode-linux-x64

