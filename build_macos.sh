#!/usr/bin/env bash
# ================================================
# build_macos.sh - Versão com ~/tmp + Progresso claro
# App: X-Spaces-Downloader
# ================================================

set -e

APP_NAME="X-Spaces-Downloader"
VERSION="1.4"
ORIGINAL_SCRIPT="downloader.sh"

echo "🔨 Iniciando build do $APP_NAME $VERSION..."

if ! command -v brew >/dev/null 2>&1; then
    echo "❌ Homebrew não encontrado!"
    exit 1
fi

if ! command -v platypus >/dev/null 2>&1; then
    echo "❌ Platypus CLI não encontrado!"
    exit 1
fi

brew install --quiet yt-dlp aria2 ffmpeg wget

# ====================== WRAPPER COM PROGRESSO ======================
cat > "XSpaceDownloader.sh" << 'EOF'
#!/usr/bin/env bash

echo "🚀 X Space Downloader iniciando..."

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ -d "$SCRIPT_DIR/bin" ]; then
    export PATH="$SCRIPT_DIR/bin:$PATH"
fi

# ==================== TELA NATIVA ====================
URL=$(osascript -e 'tell application "System Events"' \
               -e 'set dlg to display dialog "Cole a URL do X Space:" default answer "https://x.com/i/spaces/" buttons {"Cancelar", "Baixar Áudio"} default button 2 with title "X-Spaces-Downloader" with icon caution' \
               -e 'if button returned of dlg is "Baixar Áudio" then return text returned of dlg' \
               -e 'end tell' 2>/dev/null)

if [ -z "$URL" ]; then
    echo "❌ Operação cancelada."
    exit 1
fi

# Pasta temporária
TMP_DIR="$HOME/tmp/XSpaceDownloader"
mkdir -p "$TMP_DIR"
cd "$TMP_DIR" || exit 1

echo "📂 Trabalhando em: $TMP_DIR"
echo "📥 Iniciando download..."

# Executa o script original
if ! "$SCRIPT_DIR/downloader.sh" "$URL"; then
    echo "❌ Falha no download."
    osascript -e 'display dialog "❌ Download falhou.\nVerifique a URL ou sua internet." buttons {"OK"} with title "X-Spaces-Downloader" with icon stop' >/dev/null
    exit 1
fi

# Move apenas os arquivos finais para o Desktop
echo "📤 Movendo arquivos finais para o Desktop..."
mv -f *.m4a *.mp3 "$HOME/Desktop/" 2>/dev/null || true

echo "✅ Download concluído com sucesso!"
osascript -e 'display dialog "✅ Pronto!\n\nArquivos salvos no Desktop (m4a + mp3)" buttons {"OK"} with title "X-Spaces-Downloader" with icon note' >/dev/null

# Limpa temporários (opcional)
rm -rf "$TMP_DIR" 2>/dev/null || true
EOF

chmod +x "XSpaceDownloader.sh"

# ====================== BUILD ======================
rm -rf "$APP_NAME.app" 2>/dev/null || true

echo "🏗️  Criando .app com barra de progresso..."
platypus \
  -a "$APP_NAME" \
  -o "Progress Bar" \
  -u "Rodrigo Polo" \
  -V "$VERSION" \
  -I "com.rodrigopolo.xspacesdownloader" \
  -R \
  "XSpaceDownloader.sh" \
  "$APP_NAME.app"

# Copia downloader.sh original
cp "$ORIGINAL_SCRIPT" "$APP_NAME.app/Contents/Resources/downloader.sh"
chmod +x "$APP_NAME.app/Contents/Resources/downloader.sh"

# Empacota dependências
echo "📦 Empacotando binários..."
BUNDLE_BIN="$APP_NAME.app/Contents/Resources/bin"
mkdir -p "$BUNDLE_BIN"
BREW_PREFIX=$(brew --prefix)

for bin in yt-dlp aria2c ffmpeg wget; do
    if [ -f "$BREW_PREFIX/bin/$bin" ]; then
        cp "$BREW_PREFIX/bin/$bin" "$BUNDLE_BIN/"
        chmod +x "$BUNDLE_BIN/$bin"
        echo "   ✅ $bin empacotado"
    fi
done

# Assinatura + limpeza
echo "🔑 Assinando app..."
codesign --force --deep --sign - "$APP_NAME.app"
xattr -cr "$APP_NAME.app"
chmod -R 755 "$APP_NAME.app"

echo ""
echo "🎉 BUILD CONCLUÍDO!"
echo "App: $APP_NAME.app"
echo "Teste novamente."
