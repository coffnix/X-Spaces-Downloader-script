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
