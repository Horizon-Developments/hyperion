clear

echo "[HYPERION]: 🚀 Starting installer"

if ! command -v node >/dev/null 2>&1; then
  echo "[HYPERION]: 📦 Installing Node.js..."
  pkg install -y nodejs >/dev/null 2>&1
  echo "[HYPERION]: ✅ Node.js installed."
fi

rm -rf "$HOME/hyperion-relay-server"
mkdir -p "$HOME/hyperion-relay-server"

echo "[HYPERION]: 📥 Downloading files..."
curl -fsSL https://raw.githubusercontent.com/Horizon-Developments/hyperion/main/shared/hyperion-relay-server/index.js -o "$HOME/hyperion-relay-server/index.js" || exit 1
curl -fsSL https://raw.githubusercontent.com/Horizon-Developments/hyperion/main/shared/hyperion-relay-server/package.json -o "$HOME/hyperion-relay-server/package.json" || exit 1
echo "[HYPERION]: ✅ Files downloaded."

cd "$HOME/hyperion-relay-server" || exit 1

echo "[HYPERION]: 📦 Installing dependencies..."
npm install >/dev/null 2>&1
echo "[HYPERION]: ✅ Dependencies installed."

grep -qxF "alias initrelay=\"node $HOME/hyperion-relay-server/index.js\"" ~/.bashrc || \
echo "alias initrelay=\"node $HOME/hyperion-relay-server/index.js\"" >> ~/.bashrc

source ~/.bashrc

node "$HOME/hyperion-relay-server/index.js" "$1" "$2"

echo "[HYPERION]: 🎉 Init complete. Run 'initrelay' to start it."