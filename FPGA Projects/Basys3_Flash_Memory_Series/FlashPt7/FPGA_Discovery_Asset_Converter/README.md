# FPGA Discovery Asset Converter

Cross-platform Python GUI for preparing raw image and audio assets for FPGA flash.

## Supported platforms
- Windows
- Linux

The application itself is Python/Tkinter. Asset conversion is performed entirely
from the GUI; no command-line conversion workflow is required.

## Image -> RGB332
- PNG input
- Strictly 32 x 32 pixels
- RGB332, one byte per pixel
- Exactly 1,024 output bytes
- PNG alpha < 128 -> transparency key 0x5A
- Opaque black remains 0x00
- Conversion stops if an opaque color quantizes to reserved value 0x5A

## Audio -> PCM BIN
- MP3, WAV, FLAC, M4A, AAC, OGG and other formats supported by FFmpeg
- Default Part 7 format: 22,050 Hz
- Mono
- Unsigned 8-bit PCM
- One byte per sample
- 0x80 center level

## Requirements
1. Python 3
2. Tkinter
3. Pillow
4. FFmpeg + FFprobe

Install Python package dependency:

    python -m pip install -r requirements.txt

On Windows, Python's standard installer normally includes Tkinter.

On Debian/Ubuntu-family Linux systems, if Tkinter is not already installed:

    sudo apt install python3-tk

FFmpeg can either:
- be installed on the system PATH, in which case the app detects it automatically, or
- be selected from inside the GUI with the "Locate FFmpeg..." button.

On Debian/Ubuntu-family Linux systems, FFmpeg is commonly installed with:

    sudo apt install ffmpeg

## Run

Windows:

    py fpga_asset_converter.py

or:

    python fpga_asset_converter.py

Linux:

    python3 fpga_asset_converter.py

These commands only launch the GUI. Image/audio conversion itself is performed
with buttons and file dialogs inside the application.

## Part 7 note
This release intentionally accepts only 32 x 32 PNG sprites because that is the
format expected by the FPGA Discovery QSPI showcase RTL.
