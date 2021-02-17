# CDisplayAI
Comic and Manga Viewer Server Catalog with AI to recognize strips, text, TTS, etc.

![pic01](https://raw.githubusercontent.com/vhanla/CDisplayAI/main/.gitassets/pic01.png)

# WIP concept

This project aims to be a CDisplay like comic viewer, but with modern UI and few cool features like:

# Main goals

- [_] Detection of comic's individual frames using OpenCV.
- [x] Detection of comic's dialog ballon text for latter use like:
  - [ ] Translation and overlay
  - [ ] Text To Speech
- [ ] Filters like Anime4K, Waifu2x to restore/improve comic's lineart.
- [ ] Local Server Mode to serve images via REST as a way to use in another mobile viewer.
     Since mobile at your home doesn't have enough space to hold your comic collection, this will serve instead.
- [ ] Support for rearchiving using new image formats like WebP, Heif and/or Flif.
- [ ] Touchscreen friendly to give a realistic page switching animation
- [ ] Catalog database to keep track your comic directories.

As is right, now, currently this is the changelog:

# Changelog

###2021.02.17  
   - Initial commit, a simple CBR, CBZ, CB7 support to load images directly from archive.
   - Zoom with wheel and bouncing drag image viewer
   - OpenCV detection of contours
   - Easily scrolling with coverflow like animation scrolling bar           
