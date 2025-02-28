
# <img src="https://i.imgur.com/NKn3DmE.png" alt="Logo do Projeto" width="32" height="32"> cruix89 / cruix-video-archiver <img src="https://i.imgur.com/NKn3DmE.png" alt="Logo do Projeto" width="32" height="32">

[![GitHub last commit](https://img.shields.io/github/last-commit/cruix89/cruix-video-archiver?logo=github)](https://github.com/cruix89/cruix-video-archiver/actions/workflows/push-unstable-image.yml/)
[![GitHub Automated build](https://img.shields.io/github/actions/workflow/status/cruix89/cruix-video-archiver/push-release-version-image.yml?logo=github)](https://github.com/cruix89/cruix-video-archiver/actions/workflows/push-release-version-image.yml/)
[![Image Size](https://img.shields.io/docker/image-size/cruix89/cruix-video-archiver/latest?style=flat&logo=docker)](https://hub.docker.com/r/cruix89/cruix-video-archiver/)
[![Docker Pulls](https://img.shields.io/docker/pulls/cruix89/cruix-video-archiver?style=flat&logo=docker)](https://hub.docker.com/r/cruix89/cruix-video-archiver/)
[![Docker Stars](https://img.shields.io/docker/stars/cruix89/cruix-video-archiver?style=flat&logo=docker)](https://hub.docker.com/r/cruix89/cruix-video-archiver/)
[![Buy Me A Coffee](https://img.shields.io/badge/Buy%20Me%20A%20Coffee-%23FF813F?style=flat&logo=buymeacoffee)](https://buymeacoffee.com/cruix89)


--- 

## 🎼: OVERVIEW
a fully automated docker image to easily download and manage videos based in YT and other platforms supported by `yt-dlp`. With the LUFS normalization to enhance your library to the best experience. See below for more details.

---

## 💖 GENEROSITY

- 😊 **if you like me, consider** [buy me a coffee](https://buymeacoffee.com/cruix89)
- 📌 **docker hub:** [cruix-video-archiver](https://hub.docker.com/r/cruix89/cruix-video-archiver)  
- 📄 **yt-dlp documentation:** [yt-dlp](https://github.com/yt-dlp/yt-dlp)   

---

## ✨: FEATURES

- **simple setup & usage**  
  default settings for optimal operation configured automatically.
  
- **automatic updates**  
  self-updating container with automatic image creation with each `yt-dlp` release.
  
- **automated downloads**  
  specify a download URL file, and easily manage your downloads.

- **yt-dlp customization**  
  includes support for SponsorBlock, Geo Bypass, Proxy, Metadata, and more.

- **`ytsearch:` function**  
  great function that allows you to download files by keyword search. See how to use it in the "Tips and Tricks" section

- **custom output folder function**  
  great function that allows you to download files in a custom output folder. See how to use it in the "Tips and Tricks" section

- **smart caches and config files**  
  folders, cache and configuration files in the /config directory for full control of execution processes.

- **LUFS-based normalization**  
  video processing using [ffmpeg](https://github.com/FFmpeg/FFmpeg) to calculate the audio LUFS and normalize your entire /downloads library,  
  using the same parameters that major streaming platforms use, improving the sound experience and reducing volume differences between different media sources

- **designed for excellent compatibility with large media center projects**  
  the library structure is organized for great viewing on [plex](https://github.com/plexinc/pms-docker) and [jellyfin](https://jellyfin.org/docs/general/installation/container/)

---

## 🚀: QUICK START

"creating your docker container to download videos from `links.txt` URL file by docker run in your terminal:"

```bash
docker run
  -d
  --name='cruix-video-archiver'
  -e TZ="America/Sao_Paulo"
  -e 'yt_dlp_interval'='1h'
  -e 'PUID'='1000'
  -e 'PGID'='100'
  -e 'UMASK'='000'
  -v 'PATH':'/config':'rw'
  -v 'PATH':'/downloads':'rw' 'cruix89/cruix-video-archiver'
```

---

## 🔧: ENVIRONMENT PARAMETERS

| Parameter           | Default             | Description                                                      |
|---------------------|---------------------|------------------------------------------------------------------|
| `TZ`                | `America/Sao_Paulo` | set time zone for accurate log timestamps.                       |
| `PUID`              | `1000`              | specify user ID for file permissions.                            |
| `PGID`              | `100`               | specify group ID for file permissions.                           |
| `UMASK`             | `000`               | set UMASK for file permissions.                                  |
| `yt_dlp_interval`   | `1h`                | set download interval, e.g., `1h`, `12h`, or `false` to disable. |

---

## 🏷️: IMAGE TAGS

- **`unstable`**: built on new 🐙 GitHub commits; updates `yt-dlp` to latest commit.
- **`latest`**: built on new `yt-dlp` releases; auto-updates during runtime.
- **`v<VERSION>`**: built on `yt-dlp` release; does not auto-update.

---

## 📂: CONFIGURATION

- **cache folder**  
  temporary directory where files are processed, the script automatically cleans the directory after the process. 

  
- **archive.txt**  
  records downloaded video IDs, delete to re-download all.


- **args.conf**  
  stores `yt-dlp` arguments, customizable for different needs.


- **ffmpeg_cache.txt**  
  this cache file stores the files already processed by ffmpeg, if you want to reprocess your library, delete this file.


- **ffmpeg_failed_files_cache.txt**  
  this cache stores library files that were corrupted and failed in the process. If this file appears in your /config, examine the source files.


- **links.txt**  
  location: `/config/links.txt`. channel list or playlist URLs to download.


  adding a new link by .txt editing:
  ```plaintext
  # CHANNEL
  https://www.youtube.com/channel/UCePOvb3aG9w
  
  # YTSEARCH
  ytsearch10:funny-pranks-compilation
  
  # YTSEARCH TO MY CUSTOM FOLDER
  ytsearch10:funny-pranks-compilation | --output '/downloads/pranks-videos-to-my-kids/%(title)s.%(ext)s'
  ```
  adding a new link by docker command:
  ```plaintext
  docker exec cruix-music-archiver bash -c 'echo "# CHANNEL" >> ./links.txt'
  docker exec cruix-music-archiver bash -c 'echo "https://www.youtube.com/channel/UCePOvb3aG9w" >> ./links.txt'
  docker exec cruix-music-archiver bash -c 'echo "# YTSEARCH" >> ./links.txt'
  docker exec cruix-music-archiver bash -c 'echo "ytsearch10:funny-pranks-compilation" >> ./links.txt'
  docker exec cruix-music-archiver bash -c 'echo "# YTSEARCH TO MY CUSTOM FOLDER" >> ./links.txt'
  docker exec cruix-music-archiver bash -c 'echo "ytsearch10:funny-pranks-compilation | --output '/downloads/pranks-videos-to-my-kids/%(title)s.%(ext)s'" >> ./links.txt'
  ```

- **post-execution.sh**  
  these are the script that run before and after the downloads to process and manage the video files normalization.

---


## ✨ : TIPS AND TRICKS

- **`ytsearch:` function**  

configuring the function ytsearch to save in the default download folder, this function is added in the links.txt also, 
Exemple:
  ```plaintext
  ytsearch10:funny-pranks-compilation
  ```
in this case the function will save the first 10 results. Change the number to how many files you want to download 
for each search. You can place as many lines as you want, respecting one line for each search. 
Exemple:
```plaintext
  ytsearch10:funny-pranks-compilation
  ytsearch50:best-goals
  ytsearch500:karaoke
  ```
setting the custom output folder to ytsearch save your files, 
Exemple:
  ```plaintext
  ytsearch10:funny-pranks-compilation | --output '/downloads/pranks-videos-to-my-kids/%(title)s.%(ext)s'
  ytsearch50:best-goals | --output '/downloads/goals-videos-to-my-dad/%(title)s.%(ext)s'
  ytsearch500:karaoke | --output '/downloads/karaoke-songs-for-mommy/%(title)s.%(ext)s'
  ```

- **custom output folders for any link**

   it's possible to configure a custom output folder for any link, 
Exemple:
```plaintext
  https://www.youtube.com/watch?v=6VoT-KrseHA&pp=ygUHS0F | --output '/downloads/special-videos/%(title)s.%(ext)s'
  https://www.youtube.com/@anychannel | --output '/downloads/my-favorite-channels/%(title)s.%(ext)s'
  ```

---

## ❌:  EXCEPTIONS

- **unsupported arguments**
 ```plaintext
  --config-location, hardcoded to /config/args.conf.
  --batch-file, hardcoded to /config/links.txt.
  ```
  
---

## ⚙️:  DEFAULTS

- **default arguments**

| Parameter               | Default                                       | Description                                                           |
|-------------------------|-----------------------------------------------|-----------------------------------------------------------------------|
| `--output`              | `"/downloads/%(uploader)s/%(title)s.%(ext)s"` | organize the download directory for best view                         |
| `--format`              | `bestvideo[height<=1080]+bestaudio/b`         | set the download to 1080p to save space                               |
| `--force-overwrites`    | `--force-overwrites`                          | prevents duplicate files for the same video                           |
| `--merge-output-format` | `mp4`                                         | merge the audio and video download in a .mp4 file                     |
| `--windows-filenames`   | `--windows-filenames`                         | writes files with compatibility for windows system                    |
| `--trim-filenames`      | `260`                                         | maximum filename length                                               |
| `--newline`             | `--newline`                                   | logs each download progress on a line separately for better debugging |
| `--progress`            | `--progress`                                  | debug download progress                                               |
| `--embed-thumbnail`     | `--embed-thumbnail`                           | grab the thumbnail in the video file                                  |
| `--embed-metadata`      | `--embed-metadata`                            | grab the video metadata in the file                                   |
| `--embed-chapters`      | `--embed-chapters`                            | grab the chapter marks in the file                                    |
| `--sleep-requests`      | `0.1`                                         | waits for time to prevent request blocking                            |
| `--match-filter`        | `"!is_live"`                                  | prevent to download live streams causing a downloading loop           |
| `--sub-langs`           | `all,-live_chat`                              | download all subs available to the videos                             |
| `--convert-subs`        | `srt`                                         | convert all downloaded subs in srt files                              |
| `--embed-subs`          | `--embed-subs`                                | grab the subs into video file to better library management            |
 
---


## 📄:  USER AGREEMENT AND DONATIONS

This project was developed exclusively for **educational purposes and personal use**, and aims to assist users in organizing and managing their music libraries. The software uses `yt-dlp`, an open-source tool, to download content only from publicly accessible sources. It is strictly prohibited to use the software to download, distribute, or share any content protected by copyright without explicit authorization from the copyright holder.

***Important Notice:*** The software does not host, store, or distribute any media files. It does not provide direct access to any content. All downloads are initiated, managed, and controlled entirely by the user. The user is solely responsible for ensuring that the use of the software complies with all applicable copyright laws, the terms of service of the websites from which content is downloaded, and relevant local regulations. It is the user's responsibility to ensure that the downloaded content is legally available for download and distribution and that they have the proper permissions. Any unauthorized download or distribution of copyrighted content is illegal, and the user assumes full legal responsibility for such actions.

***Legal Compliance:*** By using this software, the user agrees to comply with all applicable copyright laws, the terms of service of any websites from which content is downloaded, and relevant local regulations. The developers assume no responsibility for actions taken by users that violate copyright laws or terms of service. The responsibility for legal compliance lies entirely with the user. The user must ensure that the downloaded content is legally available for download and distribution.

***Prohibition of Illegal Use:*** This software is not intended for, and must not be used for, any illegal activity. This includes, but is not limited to, downloading, distributing, or sharing copyrighted content without proper authorization. The user must not use the software to circumvent any digital rights management (DRM) or other similar protections.

***Legal Disclaimer:*** The developers do not endorse, facilitate, or support the illegal use of this software. By using the software, the user acknowledges that they are fully responsible for their actions and commit to complying with current legislation. The developers will not be responsible for any legal actions resulting from the misuse of the software.

***Donations and Sponsor:*** Donations are voluntary and do not provide any special access to content, nor do they allow bypassing legal restrictions or altering the functionality of the software in any way. Donations do not affect the user's ability to use the software and are in no way related to any access to illegal content.

---

for more `yt-dlp` options, check the [yt-dlp documentation](https://github.com/yt-dlp/yt-dlp#usage-and-options).