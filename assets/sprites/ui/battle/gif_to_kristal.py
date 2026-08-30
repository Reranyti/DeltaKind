from pathlib import Path
from PIL import Image
import json

# Папка с GIF-анимациями
INPUT_DIR = Path(r"D:\LOVE\Kristal\assets\sprites\ui\battle")

# Название GIF без расширения
GIF_NAME = "Knight_battle_idle"

gif_path = INPUT_DIR / f"{GIF_NAME}.gif"
output_dir = INPUT_DIR / GIF_NAME

if not gif_path.exists():
    raise FileNotFoundError(f"GIF не найден: {gif_path}")

output_dir.mkdir(parents=True, exist_ok=True)

with Image.open(gif_path) as gif:
    frame_count = getattr(gif, "n_frames", 1)
    frames = []

    for frame_index in range(frame_count):
        gif.seek(frame_index)

        # RGBA сохраняет прозрачность
        frame = gif.convert("RGBA")

        frame_path = output_dir / f"{frame_index + 1}.png"
        frame.save(frame_path)

        duration = gif.info.get("duration", 0)
        frames.append({
            "frame": frame_index + 1,
            "duration_ms": duration
        })

    metadata = {
        "name": GIF_NAME,
        "frames": frame_count,
        "width": gif.width,
        "height": gif.height,
        "animation": frames
    }

    with open(output_dir / "animation.json", "w", encoding="utf-8") as f:
        json.dump(metadata, f, indent=4, ensure_ascii=False)

print(f"Готово: {GIF_NAME}")
print(f"Кадров: {frame_count}")
print(f"Размер: {gif.width}x{gif.height}")
print(f"Результат: {output_dir}")