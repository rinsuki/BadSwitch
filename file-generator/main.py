import subprocess
import sys
import os
import json
from PIL import Image

SCALE = 16
WIDTH = int(512 / SCALE / 1.666)
HEIGHT = int(384 / SCALE)
FPS = int(30)

if os.environ.get("SKIP_FFMPEG_CONVERT") != "1":
    subprocess.run(["ffmpeg", "-i", sys.argv[1], "-s", "{}x{}".format(WIDTH, HEIGHT), "-pix_fmt", "gray", "-r", str(FPS), "png/%04d.png"])
    subprocess.run(["ffmpeg", "-i", sys.argv[1], "-codec", "copy", "bin/music.mp4"])

frames = []

for png in sorted(os.listdir("png")):
    if not png.endswith(".png"):
        continue
    with Image.open("png/" + png) as img:
        with open("bin/" + png[:-4] + ".bin", "wb") as f:
            f.write(bytes(img.getdata(0)))
        frames.append(png[:-4] + ".bin")

with open("bin/meta.json", "w") as f:
    json.dump({
        "width": WIDTH,
        "height": HEIGHT,
        "fps": FPS,
        "frames": frames,
    }, f)
