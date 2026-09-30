import json
import shutil
import subprocess
from pathlib import Path
import tkinter as tk
from tkinter import filedialog, messagebox, ttk

try:
    from PIL import Image, ImageTk
except ImportError:
    Image = None
    ImageTk = None

APP_TITLE = "FPGA Discovery - Asset Converter"
CONFIG_FILE = Path.home() / ".fpga_discovery_asset_converter.json"

SPRITE_W = 32
SPRITE_H = 32
TRANSPARENCY_KEY = 0x5A
ALPHA_THRESHOLD = 128


def load_config():
    try:
        return json.loads(CONFIG_FILE.read_text(encoding="utf-8"))
    except Exception:
        return {}


def save_config(config):
    try:
        CONFIG_FILE.write_text(json.dumps(config, indent=2), encoding="utf-8")
    except Exception:
        pass


def ffmpeg_path():
    configured = load_config().get("ffmpeg_path", "")
    if configured and Path(configured).is_file():
        return configured
    return shutil.which("ffmpeg")


def ffprobe_path():
    ffmpeg = ffmpeg_path()
    if ffmpeg:
        for probe_name in ("ffprobe.exe", "ffprobe"):
            sibling = Path(ffmpeg).with_name(probe_name)
            if sibling.is_file():
                return str(sibling)
    return shutil.which("ffprobe") or shutil.which("ffprobe.exe")


def rgb888_to_rgb332(r, g, b):
    return ((r >> 5) << 5) | ((g >> 5) << 2) | (b >> 6)


class App(tk.Tk):
    def __init__(self):
        super().__init__()
        self.title(APP_TITLE)
        self.geometry("780x690")
        self.minsize(760, 650)

        self.image_src = tk.StringVar()
        self.image_dst = tk.StringVar()
        self.image_dimensions = tk.StringVar(value="—")
        self.image_alpha = tk.StringVar(value="—")
        self.image_status = tk.StringVar(value="Select a 32 × 32 PNG sprite.")
        self.image_preview = None

        self.audio_src = tk.StringVar()
        self.audio_dst = tk.StringVar()
        self.audio_rate = tk.StringVar(value="22050")
        self.audio_status = tk.StringVar(value="Select FFmpeg once, then choose an audio file.")
        self.ffstat = tk.StringVar()
        self.audio_info = {
            k: tk.StringVar(value="—")
            for k in ("codec", "rate", "channels", "duration", "estimate")
        }

        self.build()
        self.refresh_ffmpeg()

    def build(self):
        outer = ttk.Frame(self)
        outer.pack(fill="both", expand=True, padx=16, pady=14)

        ttk.Label(
            outer, text="FPGA Discovery", font=("Segoe UI", 20, "bold")
        ).pack(anchor="w")
        ttk.Label(
            outer,
            text="Asset Converter — raw binary assets for FPGA flash",
            font=("Segoe UI", 12),
        ).pack(anchor="w", pady=(0, 12))

        notebook = ttk.Notebook(outer)
        notebook.pack(fill="both", expand=True)

        image_tab = ttk.Frame(notebook)
        audio_tab = ttk.Frame(notebook)
        notebook.add(image_tab, text="Image → RGB332")
        notebook.add(audio_tab, text="Audio → PCM BIN")

        self.build_image_tab(image_tab)
        self.build_audio_tab(audio_tab)

        ttk.Separator(outer).pack(fill="x", pady=(12, 8))
        ttk.Label(
            outer,
            text="IMAGE: PNG → 32×32 RGB332 → .bin     |     "
                 "AUDIO: MP3/WAV/etc. → mono unsigned 8-bit PCM → .bin",
            font=("Segoe UI", 9, "bold"),
        ).pack(anchor="w")
        ttk.Label(
            outer,
            text="Output files contain raw bytes intended for direct storage in FPGA flash.",
            font=("Segoe UI", 9),
        ).pack(anchor="w", pady=(2, 0))

    # ------------------------------------------------------------------
    # IMAGE TAB
    # ------------------------------------------------------------------
    def build_image_tab(self, parent):
        main = ttk.Frame(parent)
        main.pack(fill="both", expand=True, padx=14, pady=14)

        info = ttk.LabelFrame(main, text="Sprite Format")
        info.pack(fill="x")
        ttk.Label(
            info,
            text="Strict size: 32 × 32 pixels     •     RGB332: 1 byte/pixel     •     "
                 "Output: exactly 1,024 bytes",
        ).pack(anchor="w", padx=12, pady=(9, 3))
        ttk.Label(
            info,
            text="Transparency: PNG alpha < 128 → 0x5A     •     True black remains 0x00",
        ).pack(anchor="w", padx=12, pady=(0, 9))

        source = ttk.LabelFrame(main, text="Input PNG")
        source.pack(fill="x", pady=(10, 0))
        row = ttk.Frame(source)
        row.pack(fill="x", padx=12, pady=10)
        ttk.Entry(row, textvariable=self.image_src).pack(
            side="left", fill="x", expand=True
        )
        ttk.Button(row, text="Browse…", command=self.browse_image).pack(
            side="left", padx=(8, 0)
        )

        middle = ttk.Frame(main)
        middle.pack(fill="both", expand=True, pady=10)

        preview_frame = ttk.LabelFrame(middle, text="Preview")
        preview_frame.pack(side="left", fill="both", expand=True, padx=(0, 6))
        self.preview_label = ttk.Label(
            preview_frame, text="No PNG selected", anchor="center"
        )
        self.preview_label.pack(fill="both", expand=True, padx=12, pady=12)

        details = ttk.LabelFrame(middle, text="Source Information")
        details.pack(side="left", fill="both", expand=True, padx=(6, 0))
        grid = ttk.Frame(details)
        grid.pack(fill="both", expand=True, padx=12, pady=12)
        ttk.Label(grid, text="Dimensions:", width=15).grid(
            row=0, column=0, sticky="w", pady=4
        )
        ttk.Label(grid, textvariable=self.image_dimensions).grid(
            row=0, column=1, sticky="w", pady=4
        )
        ttk.Label(grid, text="Transparency:", width=15).grid(
            row=1, column=0, sticky="w", pady=4
        )
        ttk.Label(grid, textvariable=self.image_alpha).grid(
            row=1, column=1, sticky="w", pady=4
        )
        ttk.Label(grid, text="Pixel format:", width=15).grid(
            row=2, column=0, sticky="w", pady=4
        )
        ttk.Label(grid, text="RGB332").grid(row=2, column=1, sticky="w", pady=4)
        ttk.Label(grid, text="Transparency key:", width=15).grid(
            row=3, column=0, sticky="w", pady=4
        )
        ttk.Label(grid, text="0x5A").grid(row=3, column=1, sticky="w", pady=4)
        ttk.Label(grid, text="Expected output:", width=15).grid(
            row=4, column=0, sticky="w", pady=4
        )
        ttk.Label(grid, text="1,024 bytes").grid(
            row=4, column=1, sticky="w", pady=4
        )

        output = ttk.LabelFrame(main, text="Output BIN")
        output.pack(fill="x")
        row = ttk.Frame(output)
        row.pack(fill="x", padx=12, pady=10)
        ttk.Entry(row, textvariable=self.image_dst).pack(
            side="left", fill="x", expand=True
        )
        ttk.Button(row, text="Choose…", command=self.choose_image_output).pack(
            side="left", padx=(8, 0)
        )

        ttk.Button(
            main,
            text="Convert PNG to RGB332 BIN",
            command=self.convert_image,
        ).pack(fill="x", pady=(12, 8), ipady=7)
        ttk.Label(
            main, textvariable=self.image_status, wraplength=700
        ).pack(anchor="w")

    def require_pillow(self):
        if Image is None:
            raise RuntimeError(
                "Pillow is required for PNG conversion.\n\n"
                "Install it once with:\n"
                "py -m pip install pillow"
            )

    def browse_image(self):
        try:
            self.require_pillow()
            filename = filedialog.askopenfilename(
                title="Select 32 × 32 PNG sprite",
                filetypes=[("PNG image", "*.png"), ("All files", "*.*")],
            )
            if not filename:
                return

            path = Path(filename)
            image = Image.open(path).convert("RGBA")
            width, height = image.size

            self.image_src.set(str(path))
            self.image_dst.set(str(path.with_suffix(".bin")))
            self.image_dimensions.set(f"{width} × {height}")

            alpha_values = [a for _, _, _, a in image.getdata()]
            transparent = sum(a < ALPHA_THRESHOLD for a in alpha_values)
            self.image_alpha.set(
                f"{transparent:,} transparent pixels"
                if transparent
                else "No transparent pixels"
            )

            preview = image.resize((256, 256), Image.Resampling.NEAREST)
            self.image_preview = ImageTk.PhotoImage(preview)
            self.preview_label.configure(image=self.image_preview, text="")

            if (width, height) != (SPRITE_W, SPRITE_H):
                self.image_status.set(
                    f"INVALID SIZE — this project requires exactly "
                    f"{SPRITE_W} × {SPRITE_H} pixels."
                )
            else:
                self.image_status.set("Valid 32 × 32 sprite. Ready to convert.")
        except Exception as exc:
            messagebox.showerror(APP_TITLE, str(exc))

    def choose_image_output(self):
        filename = filedialog.asksaveasfilename(
            title="Save RGB332 binary",
            defaultextension=".bin",
            filetypes=[("Binary file", "*.bin")],
        )
        if filename:
            self.image_dst.set(filename)

    def convert_image(self):
        try:
            self.require_pillow()
            src = Path(self.image_src.get())
            dst = Path(self.image_dst.get())

            if not src.is_file():
                raise RuntimeError("Select an input PNG file.")
            if not str(dst):
                raise RuntimeError("Choose an output .bin file.")

            image = Image.open(src).convert("RGBA")
            width, height = image.size
            if (width, height) != (SPRITE_W, SPRITE_H):
                raise RuntimeError(
                    f"Image is {width} × {height}.\n\n"
                    f"This converter intentionally requires exactly "
                    f"{SPRITE_W} × {SPRITE_H} pixels."
                )

            output = bytearray()
            transparent = 0
            black = 0

            for r, g, b, a in image.getdata():
                if a < ALPHA_THRESHOLD:
                    value = TRANSPARENCY_KEY
                    transparent += 1
                else:
                    value = rgb888_to_rgb332(r, g, b)
                    if value == TRANSPARENCY_KEY:
                        raise RuntimeError(
                            "Conversion stopped because an OPAQUE pixel "
                            "quantized to reserved transparency key 0x5A.\n\n"
                            "Change that pixel color slightly and try again. "
                            "This prevents an invisible-color collision in hardware."
                        )
                    if value == 0x00:
                        black += 1
                output.append(value)

            if len(output) != 1024:
                raise RuntimeError("Internal error: output is not 1,024 bytes.")

            dst.parent.mkdir(parents=True, exist_ok=True)
            dst.write_bytes(output)

            checksum = sum(output) & 0xFFFF
            xor_checksum = 0
            for value in output:
                xor_checksum ^= value

            self.image_status.set(
                f"Complete — 1,024 bytes | transparent: {transparent} | "
                f"real black: {black} | checksum: 0x{checksum:04X} | "
                f"XOR: 0x{xor_checksum:02X}"
            )
            messagebox.showinfo(
                APP_TITLE,
                "Sprite conversion complete.\n\n"
                f"{dst}\n\n"
                "32 × 32 RGB332\n"
                "1,024 bytes\n"
                "Transparency key: 0x5A\n"
                "True black: 0x00",
            )
        except Exception as exc:
            self.image_status.set("Conversion failed.")
            messagebox.showerror(APP_TITLE, str(exc))

    # ------------------------------------------------------------------
    # AUDIO TAB
    # ------------------------------------------------------------------
    def build_audio_tab(self, parent):
        main = ttk.Frame(parent)
        main.pack(fill="both", expand=True, padx=14, pady=14)

        ff = ttk.LabelFrame(main, text="FFmpeg")
        ff.pack(fill="x")
        row = ttk.Frame(ff)
        row.pack(fill="x", padx=12, pady=10)
        ttk.Button(
            row, text="Locate FFmpeg…", command=self.select_ffmpeg
        ).pack(side="left")
        ttk.Label(row, textvariable=self.ffstat).pack(side="left", padx=12)

        source = ttk.LabelFrame(main, text="Input Audio")
        source.pack(fill="x", pady=10)
        row = ttk.Frame(source)
        row.pack(fill="x", padx=12, pady=10)
        ttk.Entry(row, textvariable=self.audio_src).pack(
            side="left", fill="x", expand=True
        )
        ttk.Button(row, text="Browse…", command=self.browse_audio).pack(
            side="left", padx=(8, 0)
        )

        source_info = ttk.LabelFrame(main, text="Source Information")
        source_info.pack(fill="x")
        grid = ttk.Frame(source_info)
        grid.pack(fill="x", padx=12, pady=10)
        labels = [
            ("Codec", "codec"),
            ("Sample rate", "rate"),
            ("Channels", "channels"),
            ("Duration", "duration"),
        ]
        for i, (label, key) in enumerate(labels):
            ttk.Label(grid, text=label + ":", width=13).grid(
                row=i // 2, column=(i % 2) * 2, sticky="w", pady=3
            )
            ttk.Label(grid, textvariable=self.audio_info[key], width=24).grid(
                row=i // 2, column=(i % 2) * 2 + 1, sticky="w"
            )

        output_format = ttk.LabelFrame(main, text="FPGA Output")
        output_format.pack(fill="x", pady=10)
        grid = ttk.Frame(output_format)
        grid.pack(fill="x", padx=12, pady=10)
        ttk.Label(grid, text="Sample rate:").grid(row=0, column=0, sticky="w")
        combo = ttk.Combobox(
            grid,
            textvariable=self.audio_rate,
            state="readonly",
            values=("16000", "22050", "32000", "44100"),
            width=12,
        )
        combo.grid(row=0, column=1, sticky="w", padx=8)
        combo.bind("<<ComboboxSelected>>", lambda event: self.estimate_audio())
        ttk.Label(
            grid, text="Mono • unsigned 8-bit PCM • one byte/sample • 0x80 center"
        ).grid(row=1, column=0, columnspan=3, sticky="w", pady=5)
        ttk.Label(grid, textvariable=self.audio_info["estimate"]).grid(
            row=2, column=0, columnspan=3, sticky="w"
        )

        output = ttk.LabelFrame(main, text="Output BIN")
        output.pack(fill="x")
        row = ttk.Frame(output)
        row.pack(fill="x", padx=12, pady=10)
        ttk.Entry(row, textvariable=self.audio_dst).pack(
            side="left", fill="x", expand=True
        )
        ttk.Button(row, text="Choose…", command=self.choose_audio_output).pack(
            side="left", padx=(8, 0)
        )

        ttk.Button(
            main,
            text="Convert Audio to FPGA BIN",
            command=self.convert_audio,
        ).pack(fill="x", pady=(12, 8), ipady=7)
        ttk.Label(
            main, textvariable=self.audio_status, wraplength=700
        ).pack(anchor="w")

    def refresh_ffmpeg(self):
        path = ffmpeg_path()
        self.ffstat.set("Ready: " + path if path else "Not selected")

    def select_ffmpeg(self):
        filename = filedialog.askopenfilename(
            title="Locate FFmpeg executable",
            filetypes=[("All files", "*.*")],
        )
        if not filename:
            return
        path = Path(filename)
        valid_names = {"ffmpeg", "ffmpeg.exe"}
        if path.name.lower() not in valid_names:
            messagebox.showerror(
                APP_TITLE,
                "Please select the FFmpeg executable (ffmpeg or ffmpeg.exe)."
            )
            return

        probe_found = any(
            path.with_name(name).is_file()
            for name in ("ffprobe", "ffprobe.exe")
        )
        if not probe_found and not (shutil.which("ffprobe") or shutil.which("ffprobe.exe")):
            messagebox.showerror(
                APP_TITLE,
                "FFprobe was not found. Keep ffprobe in the same folder as "
                "FFmpeg, or install both on the system PATH."
            )
            return
        config = load_config()
        config["ffmpeg_path"] = str(path)
        save_config(config)
        self.refresh_ffmpeg()
        self.audio_status.set(
            "FFmpeg location saved. You only need to select it once."
        )

    def probe_audio(self, path):
        executable = ffprobe_path()
        if not executable:
            raise RuntimeError("FFmpeg was not found. Install FFmpeg on PATH or use Locate FFmpeg.")
        result = subprocess.run(
            [
                executable,
                "-v", "error",
                "-select_streams", "a:0",
                "-show_entries",
                "stream=codec_name,sample_rate,channels:format=duration",
                "-of", "json",
                str(path),
            ],
            capture_output=True,
            text=True,
        )
        if result.returncode:
            raise RuntimeError(result.stderr)
        parsed = json.loads(result.stdout)
        if not parsed.get("streams"):
            raise RuntimeError("No audio stream was found in this file.")
        stream = parsed["streams"][0]
        duration = float(parsed["format"]["duration"])
        return stream, duration

    def browse_audio(self):
        filename = filedialog.askopenfilename(
            title="Select audio file",
            filetypes=[
                ("Audio", "*.mp3 *.wav *.flac *.m4a *.aac *.ogg"),
                ("All files", "*.*"),
            ],
        )
        if not filename:
            return
        self.audio_src.set(filename)
        self.audio_dst.set(str(Path(filename).with_suffix(".bin")))
        try:
            stream, duration = self.probe_audio(Path(filename))
            self.audio_duration = duration
            self.audio_info["codec"].set(
                stream.get("codec_name", "?").upper()
            )
            self.audio_info["rate"].set(
                str(stream.get("sample_rate", "?")) + " Hz"
            )
            self.audio_info["channels"].set(str(stream.get("channels", "?")))
            self.audio_info["duration"].set(
                f"{int(duration // 60)}:{duration % 60:05.2f}"
            )
            self.estimate_audio()
            self.audio_status.set("Ready to convert.")
        except Exception as exc:
            messagebox.showerror(APP_TITLE, str(exc))

    def estimate_audio(self):
        if hasattr(self, "audio_duration"):
            samples = round(self.audio_duration * int(self.audio_rate.get()))
            self.audio_info["estimate"].set(
                f"Estimated size: {samples:,} bytes "
                f"({samples / 1048576:.2f} MiB)"
            )

    def choose_audio_output(self):
        filename = filedialog.asksaveasfilename(
            title="Save PCM binary",
            defaultextension=".bin",
            filetypes=[("Binary file", "*.bin")],
        )
        if filename:
            self.audio_dst.set(filename)

    def convert_audio(self):
        try:
            executable = ffmpeg_path()
            if not executable:
                raise RuntimeError("FFmpeg was not found. Install FFmpeg on PATH or use Locate FFmpeg.")

            src = Path(self.audio_src.get())
            dst = Path(self.audio_dst.get())
            if not src.is_file():
                raise RuntimeError("Select an input audio file.")

            rate = int(self.audio_rate.get())
            self.audio_status.set("Converting…")
            self.update_idletasks()

            # Ask FFmpeg for signed 8-bit PCM, then flip bit 7 to convert each
            # sample to unsigned 8-bit PCM. This preserves the proven behavior
            # of the standalone FPGA Discovery audio converter.
            result = subprocess.run(
                [
                    executable,
                    "-y",
                    "-hide_banner",
                    "-loglevel", "error",
                    "-i", str(src),
                    "-vn",
                    "-ac", "1",
                    "-ar", str(rate),
                    "-f", "s8",
                    "pipe:1",
                ],
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
            )
            if result.returncode:
                raise RuntimeError(
                    result.stderr.decode(errors="replace")
                )

            data = bytes(value ^ 0x80 for value in result.stdout)
            dst.parent.mkdir(parents=True, exist_ok=True)
            dst.write_bytes(data)

            self.audio_status.set(
                f"Complete — {len(data):,} samples/bytes, "
                f"{len(data) / rate:.2f} seconds."
            )
            messagebox.showinfo(
                APP_TITLE,
                "Audio conversion complete.\n\n"
                f"{dst}\n\n"
                f"{len(data):,} bytes\n"
                f"{rate:,} Hz • mono • unsigned 8-bit PCM",
            )
        except Exception as exc:
            self.audio_status.set("Conversion failed.")
            messagebox.showerror(APP_TITLE, str(exc))


if __name__ == "__main__":
    App().mainloop()
