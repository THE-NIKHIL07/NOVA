import os
from PIL import Image

src_image_path = r"C:\Users\NIKHIL\.gemini\antigravity\brain\b03af2bf-d071-4d27-905f-da7024e3bfb0\.user_uploaded\media_1786890358344.png"
res_dir = r"C:\Users\NIKHIL\Desktop\nova\android\app\src\main\res"

sizes = {
    "mipmap-mdpi": (48, 48),
    "mipmap-hdpi": (72, 72),
    "mipmap-xhdpi": (96, 96),
    "mipmap-xxhdpi": (144, 144),
    "mipmap-xxxhdpi": (192, 192),
}

img = Image.open(src_image_path)

# Crop tighter to zoom in on the central Nova gear emblem
w, h = img.size
min_dim = min(w, h)

# Zoom factor: crop 50% of min_dim around center for a clean 2x zoom!
crop_size = min_dim * 0.50
left = (w - crop_size) / 2
top = (h - crop_size) / 2
right = (w + crop_size) / 2
bottom = (h + crop_size) / 2

zoomed_img = img.crop((left, top, right, bottom))

for folder, (width, height) in sizes.items():
    target_dir = os.path.join(res_dir, folder)
    os.makedirs(target_dir, exist_ok=True)
    
    resized_img = zoomed_img.resize((width, height), Image.Resampling.LANCZOS)
    
    # Save standard launcher icon
    target_file = os.path.join(target_dir, "ic_launcher.png")
    resized_img.save(target_file, "PNG")
    
    # Save foreground icon
    fg_file = os.path.join(target_dir, "ic_launcher_foreground.png")
    resized_img.save(fg_file, "PNG")
    
    print(f"Saved zoomed icon: {target_file}")

print("Zoomed Nova logo icons generated successfully!")
