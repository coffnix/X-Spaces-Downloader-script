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

## ⚠️ Notes

- Requires access to the Space via your browser cookies, currently using Opera
- Make sure you are logged in if the Space is restricted
- Temporary files are automatically cleaned after execution
