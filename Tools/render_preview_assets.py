"""Assemble a slideshow GIF from captured PNGs; no app recording or UI fabrication."""
from __future__ import annotations

from pathlib import Path

from PIL import Image


ROOT = Path(__file__).resolve().parents[1]
SCREENSHOTS = ROOT / "Assets" / "NativeCaptures" / "0.3.0-rc.1"
GIFS = ROOT / "Assets" / "GIFs"

FRAME_NAMES = [
    "main-window.partial.png",
    "menu-dashboard.partial.png",
    "command-palette.partial.png",
    "settings.partial.png",
]

CANVAS_SIZE = (1600, 1000)
CANVAS_COLOR = (8, 12, 18)


def load_frame(path: Path) -> Image.Image:
    if not path.exists():
        raise FileNotFoundError(f"Missing screenshot: {path}")

    image = Image.open(path).convert("RGBA")
    image.thumbnail((CANVAS_SIZE[0] - 96, CANVAS_SIZE[1] - 96), Image.Resampling.LANCZOS)

    canvas = Image.new("RGBA", CANVAS_SIZE, CANVAS_COLOR + (255,))
    x = (CANVAS_SIZE[0] - image.width) // 2
    y = (CANVAS_SIZE[1] - image.height) // 2
    canvas.alpha_composite(image, (x, y))
    return canvas.convert("P", palette=Image.Palette.ADAPTIVE)


def main() -> None:
    GIFS.mkdir(parents=True, exist_ok=True)
    frames = [load_frame(SCREENSHOTS / name) for name in FRAME_NAMES]
    frames[0].save(
        GIFS / "rc-native-content-captures.gif",
        save_all=True,
        append_images=frames[1:],
        duration=[1500, 1500, 1500, 1500],
        loop=0,
        optimize=True,
    )


if __name__ == "__main__":
    main()
