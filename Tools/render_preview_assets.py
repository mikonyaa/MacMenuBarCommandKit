from __future__ import annotations

from pathlib import Path

from PIL import Image, ImageDraw, ImageFont


ROOT = Path(__file__).resolve().parents[1]
SCREENSHOTS = ROOT / "Assets" / "Screenshots"
GIFS = ROOT / "Assets" / "GIFs"
FONT = "/System/Library/Fonts/SFNS.ttf"
ROUNDED = "/System/Library/Fonts/SFNSRounded.ttf"


def font(size: int, rounded: bool = False) -> ImageFont.FreeTypeFont:
    try:
        return ImageFont.truetype(ROUNDED if rounded else FONT, size=size)
    except OSError:
        return ImageFont.load_default(size=size)


def rounded(draw: ImageDraw.ImageDraw, rect: tuple[int, int, int, int], radius: int, fill, outline=None, width: int = 1) -> None:
    draw.rounded_rectangle(rect, radius=radius, fill=fill, outline=outline, width=width)


def text(draw: ImageDraw.ImageDraw, xy: tuple[int, int], value: str, size: int, fill, rounded_font: bool = False) -> None:
    draw.text(xy, value, font=font(size, rounded_font), fill=fill)


def icon(draw: ImageDraw.ImageDraw, rect: tuple[int, int, int, int], label: str, fill=(44, 104, 255)) -> None:
    rounded(draw, rect, 18, fill)
    bbox = draw.textbbox((0, 0), label, font=font(26, True))
    x = rect[0] + (rect[2] - rect[0] - bbox[2] + bbox[0]) / 2
    y = rect[1] + (rect[3] - rect[1] - bbox[3] + bbox[1]) / 2 - 2
    draw.text((x, y), label, font=font(26, True), fill=(255, 255, 255))


def command_row(draw: ImageDraw.ImageDraw, y: int, title_value: str, subtitle: str, shortcut: str, selected: bool = False) -> None:
    fill = (233, 239, 255) if selected else (255, 255, 255)
    rounded(draw, (100, y, 780, y + 76), 18, fill, (224, 228, 236))
    icon(draw, (122, y + 15, 168, y + 61), "⌘", (67, 97, 238))
    text(draw, (188, y + 14), title_value, 24, (30, 34, 42), True)
    text(draw, (188, y + 43), subtitle, 16, (104, 111, 124), True)
    rounded(draw, (690, y + 23, 752, y + 53), 10, (240, 242, 246), (225, 228, 234))
    text(draw, (706, y + 28), shortcut, 16, (92, 98, 110), True)


def draw_main_window() -> Image.Image:
    img = Image.new("RGB", (1600, 1000), (235, 238, 244))
    draw = ImageDraw.Draw(img)
    rounded(draw, (90, 80, 1510, 920), 34, (248, 249, 252), (207, 212, 224), 2)
    rounded(draw, (90, 80, 380, 920), 34, (232, 236, 246), (207, 212, 224), 2)
    for i, color in enumerate([(255, 95, 87), (255, 190, 46), (40, 200, 64)]):
        draw.ellipse((126 + i * 28, 116, 142 + i * 28, 132), fill=color)
    text(draw, (126, 168), "CommandKit", 30, (34, 40, 54), True)
    for i, item in enumerate(["Today", "Quick Actions", "Recent Commands", "System Status"]):
        y = 230 + i * 58
        fill = (213, 222, 250) if i == 0 else None
        if fill:
            rounded(draw, (120, y - 11, 344, y + 36), 14, fill)
        text(draw, (142, y), item, 21, (45, 52, 68), True)
    text(draw, (430, 140), "AI Command Center", 56, (24, 29, 39), True)
    text(draw, (432, 212), "Menu bar commands, local state, settings, and keyboard-first workflows.", 24, (96, 104, 119), True)
    rounded(draw, (1270, 146, 1458, 202), 18, (42, 111, 255))
    text(draw, (1306, 161), "Run Command", 21, (255, 255, 255), True)
    cards = [("Commands", "42", "run today"), ("Focus", "2.5h", "protected"), ("Inbox", "7", "items waiting")]
    for i, (title_value, value, caption) in enumerate(cards):
        x = 430 + i * 330
        rounded(draw, (x, 290, x + 288, 470), 24, (255, 255, 255), (224, 228, 236), 2)
        text(draw, (x + 28, 326), value, 48, (26, 32, 43), True)
        text(draw, (x + 30, 392), title_value, 23, (48, 55, 70), True)
        text(draw, (x + 30, 426), caption, 17, (105, 112, 126), True)
    text(draw, (430, 540), "Quick Actions", 32, (30, 36, 49), True)
    for idx, row in enumerate([
        ("New Note", "Capture a short AI-ready note.", "⌘N"),
        ("Summarize Clipboard", "Turn copied text into a concise brief.", "⇧⌘S"),
        ("Toggle Focus Mode", "Quiet the dashboard.", "⌥⌘F"),
    ]):
        command_row(draw, 598 + idx * 92, *row, selected=idx == 0)
    return img


def draw_menu_dashboard() -> Image.Image:
    img = Image.new("RGB", (900, 900), (235, 238, 244))
    draw = ImageDraw.Draw(img)
    rounded(draw, (220, 80, 680, 820), 34, (248, 249, 252), (207, 212, 224), 2)
    icon(draw, (252, 122, 308, 178), "✦", (42, 111, 255))
    text(draw, (326, 124), "CommandKit", 30, (28, 34, 46), True)
    text(draw, (326, 160), "Ready", 18, (99, 107, 122), True)
    rounded(draw, (548, 132, 634, 166), 17, (226, 245, 234), (184, 229, 203))
    text(draw, (570, 139), "Ready", 15, (32, 135, 76), True)
    rounded(draw, (252, 214, 648, 268), 15, (238, 241, 247), (221, 225, 234))
    text(draw, (280, 230), "Run a command", 19, (104, 111, 124), True)
    text(draw, (252, 310), "Quick Commands", 23, (31, 38, 52), True)
    for idx, row in enumerate([
        ("New Note", "Capture a short note.", "⌘N"),
        ("Start Timer", "Begin focus block.", "⇧⌘T"),
        ("Summarize Clipboard", "Create a brief.", "⇧⌘S"),
    ]):
        y = 354 + idx * 86
        rounded(draw, (252, y, 648, y + 68), 16, (255, 255, 255), (224, 228, 236))
        text(draw, (276, y + 13), row[0], 21, (31, 38, 52), True)
        text(draw, (276, y + 40), row[1], 15, (100, 108, 124), True)
        text(draw, (580, y + 24), row[2], 15, (100, 108, 124), True)
    rounded(draw, (252, 648, 648, 744), 20, (255, 255, 255), (224, 228, 236))
    text(draw, (280, 672), "42", 40, (28, 34, 46), True)
    text(draw, (340, 686), "commands run today", 20, (95, 104, 119), True)
    return img


def draw_palette() -> Image.Image:
    img = Image.new("RGB", (1200, 900), (232, 235, 242))
    draw = ImageDraw.Draw(img)
    rounded(draw, (210, 120, 990, 780), 30, (250, 251, 253), (207, 212, 224), 2)
    text(draw, (258, 170), "Search commands", 34, (94, 102, 118), True)
    draw.line((210, 236, 990, 236), fill=(218, 222, 232), width=2)
    for idx, row in enumerate([
        ("New Note", "Capture a short AI-ready note.", "⌘N"),
        ("Start Timer", "Begin a 25-minute focus block.", "⇧⌘T"),
        ("Summarize Clipboard", "Turn copied text into a concise brief.", "⇧⌘S"),
        ("Open Dashboard", "Show the full command workspace.", "⌘D"),
        ("Toggle Focus Mode", "Quiet the dashboard.", "⌥⌘F"),
    ]):
        command_row(draw, 270 + idx * 88, *row, selected=idx == 0)
    return img


def draw_settings() -> Image.Image:
    img = Image.new("RGB", (1200, 800), (235, 238, 244))
    draw = ImageDraw.Draw(img)
    rounded(draw, (170, 90, 1030, 710), 30, (250, 251, 253), (207, 212, 224), 2)
    text(draw, (230, 142), "Settings", 42, (28, 34, 46), True)
    tabs = ["General", "Appearance", "Commands", "About"]
    for idx, tab in enumerate(tabs):
        x = 230 + idx * 178
        rounded(draw, (x, 214, x + 148, 258), 15, (226, 234, 255) if idx == 0 else (241, 243, 247), (220, 225, 235))
        text(draw, (x + 24, 226), tab, 18, (38, 45, 60), True)
    rows = [
        ("Launch at Login", "Disabled"),
        ("Menu bar presentation", "Balanced"),
        ("Theme preference", "System"),
        ("Demo data", "Enabled"),
    ]
    for idx, (name, value) in enumerate(rows):
        y = 320 + idx * 72
        rounded(draw, (230, y, 970, y + 56), 14, (255, 255, 255), (225, 229, 237))
        text(draw, (256, y + 17), name, 20, (35, 42, 56), True)
        text(draw, (840, y + 17), value, 18, (94, 102, 118), True)
    return img


def main() -> None:
    SCREENSHOTS.mkdir(parents=True, exist_ok=True)
    GIFS.mkdir(parents=True, exist_ok=True)
    frames = [
        draw_main_window(),
        draw_menu_dashboard().resize((1600, 1000)),
        draw_palette().resize((1600, 1200)).crop((0, 100, 1600, 1100)),
    ]
    draw_main_window().save(SCREENSHOTS / "main-window.png")
    draw_menu_dashboard().save(SCREENSHOTS / "menu-dashboard.png")
    draw_palette().save(SCREENSHOTS / "command-palette.png")
    draw_settings().save(SCREENSHOTS / "settings.png")
    frames[0].save(
        GIFS / "mac-menu-bar-command-kit.gif",
        save_all=True,
        append_images=frames[1:],
        duration=1300,
        loop=0,
        optimize=True,
    )


if __name__ == "__main__":
    main()
