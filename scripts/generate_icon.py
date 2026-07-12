"""Generate skeuomorphic camera-lens icon with metallic & glass effects."""
from PIL import Image, ImageDraw, ImageFilter
import math, os, tempfile, struct

SIZES = [16, 24, 32, 48, 64, 128, 256]

# ── Color palette ──
OUTER_DARK  = (40, 42, 46)     # gunmetal dark
OUTER_MID   = (80, 84, 90)     # gunmetal mid
OUTER_LIGHT = (120, 125, 132)  # gunmetal light
INNER_DARK  = (25, 27, 30)     # inner ring dark
LENS_BLUE   = (30, 80, 180)    # blue glass tint
LENS_CYAN   = (80, 160, 240)   # lighter glass edge
HIGHLIGHT   = (255, 255, 255)  # specular shine


def draw_metallic_ring(draw, cx, cy, outer_r, inner_r, dark, mid, light, angle_deg=135):
    """Draw a metallic ring with a gradient-like effect using sectors."""
    steps = 64
    for i in range(steps):
        a1 = (i / steps) * 360
        a2 = ((i + 1) / steps) * 360
        # Determine "lightness" based on angle relative to light source
        mid_a = (a1 + a2) / 2
        diff = abs(((mid_a - angle_deg + 180) % 360) - 180)  # distance from highlight
        t = min(1.0, diff / 180.0)
        # Interpolate between light and dark
        r = int(mid[0] + (dark[0] - mid[0]) * t)
        g = int(mid[1] + (dark[1] - mid[1]) * t)
        b = int(mid[2] + (dark[2] - mid[2]) * t)
        color = (r, g, b)

        # Draw a thin pie slice
        draw.pieslice(
            [cx - outer_r, cy - outer_r, cx + outer_r, cy + outer_r],
            start=a1, end=a2, fill=color, outline=color,
        )


def draw_lens_glass(img, draw, cx, cy, r):
    """Draw glass lens with blue tint and specular highlight."""
    # Base dark glass
    for i, (c, rr) in enumerate([
        (LENS_BLUE, r),
        ((50, 110, 200), r * 0.85),
        ((70, 140, 220), r * 0.65),
        ((40, 90, 190), r * 0.5),
    ]):
        draw.ellipse([cx - rr, cy - rr, cx + rr, cy + rr], fill=c)

    # Specular highlight — curved white arc at upper-left
    # Use a large white ellipse shifted upward, then clip
    overlay = Image.new("RGBA", img.size, (0, 0, 0, 0))
    ov_draw = ImageDraw.Draw(overlay)

    # Main specular shine
    shine_cx = cx - r * 0.25
    shine_cy = cy - r * 0.3
    shine_rx = r * 0.45
    shine_ry = r * 0.3
    ov_draw.ellipse(
        [shine_cx - shine_rx, shine_cy - shine_ry,
         shine_cx + shine_rx, shine_cy + shine_ry],
        fill=(255, 255, 255, 180),
    )

    # Smaller secondary shine
    shine2_cx = cx + r * 0.4
    shine2_cy = cy + r * 0.45
    shine2_r = r * 0.08
    ov_draw.ellipse(
        [shine2_cx - shine2_r, shine2_cy - shine2_r,
         shine2_cx + shine2_r, shine2_cy + shine2_r],
        fill=(255, 255, 255, 80),
    )

    # Clip overlay by lens circle
    mask = Image.new("L", img.size, 0)
    mask_draw = ImageDraw.Draw(mask)
    mask_draw.ellipse([cx - r, cy - r, cx + r, cy + r], fill=255)
    img.paste(overlay, (0, 0), mask)


def draw_aperture_blades(draw, cx, cy, r, count=6):
    """Draw aperture blade lines inside the lens."""
    if r < 10:
        return
    for i in range(count):
        angle = (i / count) * 2 * math.pi
        x1 = cx + math.cos(angle) * r * 0.3
        y1 = cy + math.sin(angle) * r * 0.3
        x2 = cx + math.cos(angle) * r * 0.85
        y2 = cy + math.sin(angle) * r * 0.85
        draw.line([(x1, y1), (x2, y2)], fill=(20, 22, 26, 120), width=max(1, int(r // 25)))


images = []

for s in SIZES:
    img = Image.new("RGBA", (s, s), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    cx, cy = s / 2, s / 2
    max_r = s / 2 - max(1, s // 20)

    # ── Drop shadow (subtle, behind the lens) ──
    shadow_r = max_r - max(1, s // 40)
    shadow_img = Image.new("RGBA", (s, s), (0, 0, 0, 0))
    shadow_draw = ImageDraw.Draw(shadow_img)
    shadow_offset = max(1, s // 64)
    shadow_draw.ellipse(
        [cx - shadow_r + shadow_offset, cy - shadow_r + shadow_offset * 2,
         cx + shadow_r + shadow_offset, cy + shadow_r + shadow_offset * 2],
        fill=(0, 0, 0, 60),
    )
    shadow_img = shadow_img.filter(ImageFilter.GaussianBlur(radius=max(1, s / 25)))
    img = Image.alpha_composite(img, shadow_img)
    draw = ImageDraw.Draw(img)

    # ── Outer metallic ring ──
    outer_r = max_r
    outer_inner_r = outer_r * 0.82
    draw_metallic_ring(draw, cx, cy, outer_r, outer_inner_r,
                        OUTER_DARK, OUTER_MID, OUTER_LIGHT)

    # Ring edge highlight (thin bright rim)
    rim_w = max(1, s // 80)
    draw.ellipse(
        [cx - outer_r + rim_w, cy - outer_r + rim_w,
         cx + outer_r - rim_w, cy + outer_r - rim_w],
        outline=(160, 165, 175, 120), width=rim_w,
    )

    # ── Inner dark ring ──
    inner_r = outer_inner_r * 0.94
    inner_inner_r = inner_r * 0.9
    draw_metallic_ring(draw, cx, cy, inner_r, inner_inner_r,
                        INNER_DARK, (50, 54, 60), (70, 74, 80))

    # ── Glass lens ──
    glass_r = inner_inner_r * 0.92
    draw_lens_glass(img, draw, cx, cy, glass_r)

    # ── Aperture blades (on glass) ──
    draw_aperture_blades(draw, cx, cy, glass_r, count=6)

    # ── Inner micro-ring (lens element separator) ──
    if s >= 64:
        micro_r = glass_r * 0.5
        draw.ellipse(
            [cx - micro_r, cy - micro_r, cx + micro_r, cy + micro_r],
            outline=(40, 44, 50, 100), width=max(1, s // 100),
        )

    images.append(img)


# ── Save as multi-resolution ICO ──
output_path = "app.ico"
entries = []

for i, s in enumerate(SIZES):
    buf = images[i].resize((s, s), Image.LANCZOS)
    png_buf = tempfile.NamedTemporaryFile(suffix=".png", delete=False)
    png_path = png_buf.name
    png_buf.close()
    buf.save(png_path, format="PNG")
    with open(png_path, "rb") as f:
        png_bytes = f.read()
    os.unlink(png_path)
    entries.append((s, s, png_bytes))

header = struct.pack("<HHH", 0, 1, len(entries))
entry_table = b""
image_data = b""
offset = 6 + 16 * len(entries)

for w, h, data in entries:
    rw = 0 if w >= 256 else w
    rh = 0 if h >= 256 else h
    entry_table += struct.pack(
        "<BBBBHHII", rw, rh, 0, 0, 1, 32, len(data), offset
    )
    offset += len(data)
    image_data += data

with open(output_path, "wb") as f:
    f.write(header + entry_table + image_data)

print(f"Generated {output_path}  sizes={SIZES}  total={len(image_data)} bytes")
