#!/usr/bin/env bash
# ================================================
# build_macos.sh - Versão com ~/tmp + Progresso claro
# App: X-Spaces-Downloader
# ================================================

set -e

rm -rf 'X-Spaces-Downloader Installer.dmg' X-Spaces-Downloader.app

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

rm -rf /tmp/xspaces.iconset
mkdir -p /tmp/xspaces.iconset

sips -z 16 16     icon.png --out /tmp/xspaces.iconset/icon_16x16.png
sips -z 32 32     icon.png --out /tmp/xspaces.iconset/icon_16x16@2x.png
sips -z 32 32     icon.png --out /tmp/xspaces.iconset/icon_32x32.png
sips -z 64 64     icon.png --out /tmp/xspaces.iconset/icon_32x32@2x.png
sips -z 128 128   icon.png --out /tmp/xspaces.iconset/icon_128x128.png
sips -z 256 256   icon.png --out /tmp/xspaces.iconset/icon_128x128@2x.png
sips -z 256 256   icon.png --out /tmp/xspaces.iconset/icon_256x256.png
sips -z 512 512   icon.png --out /tmp/xspaces.iconset/icon_256x256@2x.png
sips -z 512 512   icon.png --out /tmp/xspaces.iconset/icon_512x512.png
sips -z 1024 1024 icon.png --out /tmp/xspaces.iconset/icon_512x512@2x.png

iconutil -c icns /tmp/xspaces.iconset

cp /tmp/xspaces.icns X-Spaces-Downloader.app/Contents/Resources/X-Spaces-Downloader.icns

plutil -convert xml1 X-Spaces-Downloader.app/Contents/Info.plist

/usr/libexec/PlistBuddy -c "Delete :CFBundleIconName" X-Spaces-Downloader.app/Contents/Info.plist 2>/dev/null || true

/usr/libexec/PlistBuddy -c "Set :CFBundleIconFile X-Spaces-Downloader" X-Spaces-Downloader.app/Contents/Info.plist 2>/dev/null || \
/usr/libexec/PlistBuddy -c "Add :CFBundleIconFile string X-Spaces-Downloader" X-Spaces-Downloader.app/Contents/Info.plist

plutil -convert binary1 X-Spaces-Downloader.app/Contents/Info.plist

APP="X-Spaces-Downloader.app"

#killall X-Spaces-Downloader 2>/dev/null

xattr -cr "$APP"

rm -rf "$APP/Contents/_CodeSignature"

find "$APP/Contents" -type f -perm +111 -exec codesign --remove-signature {} \; 2>/dev/null

codesign --force --sign - "$APP/Contents/Resources/bin/wget"
codesign --force --sign - "$APP/Contents/Resources/bin/ffmpeg"
codesign --force --sign - "$APP/Contents/Resources/bin/aria2c"
codesign --force --sign - "$APP/Contents/Resources/bin/yt-dlp"
codesign --force --sign - "$APP/Contents/MacOS/X-Spaces-Downloader"

codesign --force --deep --sign - "$APP"

codesign --verify --deep --strict --verbose=4 "$APP"
spctl --assess --type execute --verbose=4 "$APP" || true

touch "$APP"

create-dmg \
  --volname "X-Spaces-Downloader" \
  --window-pos 200 120 \
  --window-size 800 400 \
  --volicon /tmp/xspaces.icns \
  --icon "X-Spaces-Downloader.app" 200 190 \
  --app-drop-link 600 190 \
  "X-Spaces-Downloader Installer.dmg" \
  "X-Spaces-Downloader.app"
