# Twitter/X Space Downloader

Simple bash script to download audio from Twitter/X Spaces.

It fetches the stream URL, downloads all audio chunks and merges them into a single file.

## 📦 Dependencies

Make sure you have the following installed:

- yt-dlp
- wget
- aria2c
- ffmpeg

## ⚙️ Usage

First, make the script executable:

```bash
chmod +x downloader.sh
```

Run the script with the Twitter/X Space URL as the first argument:

```
./downloader.sh <URL>
```
Example:

```
./downloader.sh https://twitter.com/i/spaces/XXXXXXXX
```
## 📁 Output

The script generates a final audio file with a name based on:

- upload date
- uploader
- title
- id


## Build app (macOS)
```
bash -x build_macos.sh
```

## Create DMG:
```
create-dmg \
  --volname "X-Spaces-Downloader" \
  --window-pos 200 120 \
  --window-size 800 400 \
  --icon-size 110 \
  --icon "X-Spaces-Downloader.app" 200 190 \
  --app-drop-link 600 190 \
  "X-Spaces-Downloader Installer.dmg" \
  "X-Spaces-Downloader.app"
  ```

## ⚠️ Notes

- Requires access to the Space via your browser cookies, currently using Opera
- Make sure you are logged in if the Space is restricted
- Temporary files are automatically cleaned after execution
- Forked from: https://gist.github.com/rodrigopolo/40029718a85963399784ae35b06adcaf

