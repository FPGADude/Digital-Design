#!/usr/bin/env python3
"""
png_to_rgb332_bin.py

Convert a PNG image into raw RGB332 sprite data for FPGA flash storage.

Output format:
    1 byte per pixel
    Row-major order: left-to-right, top-to-bottom

RGB332 layout:
    bits 7:5 = Red   (3 bits)
    bits 4:2 = Green (3 bits)
    bits 1:0 = Blue  (2 bits)

Transparency:
    PNG alpha < --alpha-threshold becomes 0x00.

Important:
    The FPGA renderer reserves 0x00 for transparency. Therefore, if an
    opaque pixel quantizes naturally to RGB332 value 0x00, this program
    remaps it to 0x01 so it remains visible instead of disappearing.

Requires:
    pip install pillow

For the FPGA Discovery Part 4 spaceship, run this on command line:

    python png_to_rgb332_bin.py spaceship.png spaceship.bin --width 32 --height 32

"""

import argparse
from pathlib import Path
from PIL import Image


def rgb888_to_rgb332(r: int, g: int, b: int) -> int:
    """Convert 8-bit RGB channels to one RGB332 byte."""
    r3 = r >> 5
    g3 = g >> 5
    b2 = b >> 6
    return (r3 << 5) | (g3 << 2) | b2


def main():
    parser = argparse.ArgumentParser(
        description="Convert a PNG image to raw RGB332 binary sprite data."
    )
    parser.add_argument("input_png", type=Path, help="Input PNG image")
    parser.add_argument("output_bin", type=Path, help="Output raw .bin file")
    parser.add_argument("--width", type=int, default=None, help="Required image width")
    parser.add_argument("--height", type=int, default=None, help="Required image height")
    parser.add_argument(
        "--alpha-threshold",
        type=int,
        default=128,
        help="Alpha values below this become transparent (default: 128)"
    )
    parser.add_argument(
        "--allow-zero-black",
        action="store_true",
        help="Allow opaque pixels to encode as 0x00."
    )

    args = parser.parse_args()

    if not args.input_png.exists():
        raise SystemExit(f"ERROR: Input file not found: {args.input_png}")

    if not 0 <= args.alpha_threshold <= 255:
        raise SystemExit("ERROR: --alpha-threshold must be between 0 and 255.")

    image = Image.open(args.input_png).convert("RGBA")
    width, height = image.size

    if args.width is not None and width != args.width:
        raise SystemExit(f"ERROR: Image width is {width}, expected {args.width}.")
    if args.height is not None and height != args.height:
        raise SystemExit(f"ERROR: Image height is {height}, expected {args.height}.")

    output = bytearray()
    transparent_pixels = 0
    remapped_black_pixels = 0

    for r, g, b, a in image.getdata():
        if a < args.alpha_threshold:
            value = 0x00
            transparent_pixels += 1
        else:
            value = rgb888_to_rgb332(r, g, b)
            if value == 0x00 and not args.allow_zero_black:
                value = 0x01
                remapped_black_pixels += 1
        output.append(value)

    args.output_bin.parent.mkdir(parents=True, exist_ok=True)
    args.output_bin.write_bytes(output)

    checksum = sum(output) & 0xFFFF
    xor_checksum = 0
    for value in output:
        xor_checksum ^= value

    print()
    print("PNG -> RGB332 conversion complete")
    print("---------------------------------")
    print(f"Input file:        {args.input_png}")
    print(f"Output file:       {args.output_bin}")
    print(f"Dimensions:        {width} x {height}")
    print(f"Pixels:            {width * height}")
    print(f"Output size:       {len(output)} bytes")
    print("Pixel format:      RGB332")
    print("Transparency:      0x00")
    print(f"Transparent px:    {transparent_pixels}")
    print(f"Remapped black px: {remapped_black_pixels}")
    print(f"16-bit checksum:   0x{checksum:04X}")
    print(f"8-bit XOR:         0x{xor_checksum:02X}")
    print()
    print("First 32 output bytes:")
    print(" ".join(f"{b:02X}" for b in output[:32]))


if __name__ == "__main__":
    main()
