"""Convert PNG to multi-resolution ICO. Usage: python script.py input.png output.ico"""
import sys
from PIL import Image
import struct, tempfile, os

SIZES = [16, 24, 32, 48, 64, 128, 256]

def png_to_ico(src_path, dst_path):
    img = Image.open(src_path).convert("RGBA")
    entries = []
    for s in SIZES:
        buf = img.resize((s, s), Image.LANCZOS)
        f = tempfile.NamedTemporaryFile(suffix=".png", delete=False)
        f.close()
        buf.save(f.name, format="PNG")
        with open(f.name, "rb") as fp:
            data = fp.read()
        os.unlink(f.name)
        entries.append((s, s, data))

    header = struct.pack("<HHH", 0, 1, len(entries))
    et = b""
    idata = b""
    off = 6 + 16 * len(entries)
    for w, h, data in entries:
        rw = 0 if w >= 256 else w
        rh = 0 if h >= 256 else h
        et += struct.pack("<BBBBHHII", rw, rh, 0, 0, 1, 32, len(data), off)
        off += len(data)
        idata += data

    with open(dst_path, "wb") as f:
        f.write(header + et + idata)
    print(f"{src_path} ({img.size[0]}x{img.size[1]}) -> {dst_path} ({len(idata)} bytes)")


if __name__ == "__main__":
    if len(sys.argv) >= 3:
        png_to_ico(sys.argv[1], sys.argv[2])
    else:
        # Default: look for icon.png in cwd, output app.ico
        png_to_ico("icon.png", "app.ico")
