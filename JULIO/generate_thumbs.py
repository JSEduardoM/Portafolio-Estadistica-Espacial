import json
import os
import re
import fitz  # PyMuPDF

base_dir = r"c:\Users\User\Documents\SEMESTRE X\ESTADISTICA ESPACIAL\PORTAFOLIO\JULIO"
manifest_path = os.path.join(base_dir, "manifest.json")

with open(manifest_path, 'r', encoding='utf-8') as f:
    manifest = json.load(f)

for i, item in enumerate(manifest):
    # Set 'unidad' if not set
    if 'unidad' not in item:
        if "Unidad 2" in item.get('title', ''):
            item['unidad'] = 2
        else:
            item['unidad'] = 1

    # Remove "Unidad 2: " or similar from title
    if item['unidad'] == 2:
        title = item.get('title', '')
        title = re.sub(r'^Unidad 2:\s*', '', title)
        item['title'] = title

    # Generate thumbnail if missing and has PDF
    if not item.get('thumbnail') and item.get('pdf'):
        pdf_path = os.path.join(base_dir, item['pdf'])
        pdf_dir = os.path.dirname(pdf_path)
        thumb_name = "thumbnail.png"
        thumb_path = os.path.join(pdf_dir, thumb_name)
        
        try:
            print(f"Generating thumbnail for {item['pdf']}")
            doc = fitz.open(pdf_path)
            page = doc.load_page(0)  # first page
            pix = page.get_pixmap(matrix=fitz.Matrix(0.5, 0.5)) # scale down to save space
            pix.save(thumb_path)
            
            # update manifest
            # Use forward slashes for URLs
            rel_thumb_path = os.path.relpath(thumb_path, base_dir).replace('\\', '/')
            item['thumbnail'] = rel_thumb_path
            print(f"Thumbnail generated and path updated to: {rel_thumb_path}")
        except Exception as e:
            print(f"Failed to generate thumbnail for {item['pdf']}: {e}")

with open(manifest_path, 'w', encoding='utf-8') as f:
    json.dump(manifest, f, indent=4, ensure_ascii=False)

print("Finished processing manifest.json")
