from PIL import Image

def remove_white_bg(image_path, output_path, tolerance=230):
    img = Image.open(image_path).convert("RGBA")
    datas = img.getdata()
    
    new_data = []
    for item in datas:
        # Change all white (also shades of whites)
        # to transparent
        if item[0] >= tolerance and item[1] >= tolerance and item[2] >= tolerance:
            new_data.append((255, 255, 255, 0))
        else:
            new_data.append(item)
            
    img.putdata(new_data)
    img.save(output_path, "PNG")

if __name__ == "__main__":
    import sys
    remove_white_bg(sys.argv[1], sys.argv[1])
