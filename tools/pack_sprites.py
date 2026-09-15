"""Union trim per animation, fixed pivot, 2px gutters; deterministic <=2048 atlases. Generates contact sheets for Milestone 2."""
from pathlib import Path
from PIL import Image, ImageDraw
import json, math

root = Path(__file__).resolve().parents[1]
out = root / 'assets/blender'
out.mkdir(parents=True, exist_ok=True)

qa_m2 = root / 'qa/blender/milestone2'
qa_m2.mkdir(parents=True, exist_ok=True)

qa_root = root / 'qa/blender'
qa_root.mkdir(parents=True, exist_ok=True)

# Find all rendered animations that have timing.json
render_dirs = sorted([p for p in (root / 'blender/renders').iterdir() if p.is_dir() and (p / 'timing.json').exists()])

library = {}
total_frames = 0

print(f"Packing {len(render_dirs)} animations into optimized sprite atlases...")

for rdir in render_dirs:
    name = rdir.name
    meta = json.loads((rdir / 'timing.json').read_text())
    frame_files = sorted(rdir.glob(name + '_????.png'))
    if not frame_files:
        continue
    
    frames = [Image.open(p).convert('RGBA') for p in frame_files]
    bounds = [im.getchannel('A').getbbox() for im in frames]
    # Filter out empty frames if any, otherwise fallback to full 320x320
    valid_bounds = [b for b in bounds if b is not None]
    if not valid_bounds:
        valid_bounds = [(0, 0, 320, 320)]
    
    min_x = max(0, min(b[0] for b in valid_bounds) - 4)
    min_y = max(0, min(b[1] for b in valid_bounds) - 4)
    max_x = min(320, max(b[2] for b in valid_bounds) + 4)
    max_y = min(320, max(b[3] for b in valid_bounds) + 4)
    
    box = (min_x, min_y, max_x, max_y)
    w, h = box[2] - box[0], box[3] - box[1]
    
    cols = min(8, max(1, 2048 // (w + 4)))
    rows = math.ceil(len(frames) / cols)
    atlas_w = cols * (w + 4)
    atlas_h = rows * (h + 4)
    
    atlas = Image.new('RGBA', (atlas_w, atlas_h), (0, 0, 0, 0))
    rects = []
    
    # Contact sheet preview
    preview_col_w = 200
    preview_row_h = 240
    preview = Image.new('RGB', (cols * preview_col_w, rows * preview_row_h), (42, 45, 54))
    draw = ImageDraw.Draw(preview)
    
    for i, im in enumerate(frames):
        gx = (i % cols) * (w + 4) + 2
        gy = (i // cols) * (h + 4) + 2
        crop = im.crop(box)
        atlas.paste(crop, (gx, gy))
        rects.append([gx, gy, w, h])
        
        # Draw on preview sheet
        thumb = crop.copy()
        thumb.thumbnail((preview_col_w - 20, preview_row_h - 40))
        px = (i % cols) * preview_col_w + 10
        py = (i // cols) * preview_row_h + 30
        preview.paste(thumb, (px, py), thumb)
        t_sec = meta['times'][i] if i < len(meta['times']) else 0.0
        draw.text(((i % cols) * preview_col_w + 10, (i // cols) * preview_row_h + 8), f"{name} #{i+1} ({t_sec:.2f}s)", fill=(200, 220, 240))
    
    # Save optimized runtime atlas and source atlas
    atlas_path = out / f"{name}.png"
    atlas.save(atlas_path, optimize=True)
    atlas.save(root / f"blender/spritesheets/{name}.png", optimize=True)
    
    # Save contact sheet for QA inspection
    preview.save(qa_m2 / f"{name}-contact.png")
    preview.save(qa_root / f"{name}-contact.png")
    
    orig_pivot = meta.get('pivot', [128, 296])
    pivot_x = orig_pivot[0] - box[0]
    pivot_y = orig_pivot[1] - box[1]
    
    meta.update({
        'texture': f"res://assets/blender/{name}.png",
        'rects': rects,
        'pivot': [pivot_x, pivot_y],
        'atlas_size': [atlas_w, atlas_h],
        'frame_box': [w, h]
    })
    library[name] = meta
    total_frames += len(frames)

(out / 'library.json').write_text(json.dumps(library, indent=2))
print(f"SUCCESS: Packed {len(library)} animations, {total_frames} total frames into library.json!")
