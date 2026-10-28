# Video Tools (`video_tools`)

A collection of lightweight, practical command-line scripts for handling video manipulation tasks on Ubuntu / Linux systems.

## Current Tools

### `split_mp4_file.sh`
A robust Bash script designed to split large MP4 video files into smaller parts to fit strict file system size limits (such as FAT32 / older USB memory sticks capped around 4.2 GB). 

#### Key Features:
* **Size Management:** Targets safe chunk sizes (~4.0 GB) to keep each part well under the 4.2 GB limit.
* **Seamless Overlap:** Automatically includes a **30-second overlap** at the start of each consecutive part for a smooth viewing experience.
* **Fast Stream Copying:** Uses `ffmpeg` stream copying (`-c copy`) for lightning-fast splitting without quality loss or unnecessary re-encoding.
* **Safety Checks:** 
  * Verifies that the input file exists before running.
  * Pre-calculates output filenames and exits with an error if any target file already exists, preventing accidental overwrites.

#### Prerequisites:
Make sure you have `ffmpeg` and `ffprobe` installed on your system:
```bash
sudo apt update
sudo apt install ffmpeg
```
