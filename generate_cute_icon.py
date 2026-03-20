import struct
import zlib

def create_png(width, height, pixels):
    def png_chunk(chunk_type, data):
        chunk_len = struct.pack('>I', len(data))
        chunk_crc = struct.pack('>I', zlib.crc32(chunk_type + data) & 0xffffffff)
        return chunk_len + chunk_type + data + chunk_crc

    signature = b'\x89PNG\r\n\x1a\n'
    ihdr_data = struct.pack('>IIBBBBB', width, height, 8, 2, 0, 0, 0)
    ihdr = png_chunk(b'IHDR', ihdr_data)
    raw_data = b''
    for y in range(height):
        raw_data += b'\x00'
        for x in range(width):
            raw_data += bytes(pixels[y * width + x])
    compressed = zlib.compress(raw_data, 9)
    idat = png_chunk(b'IDAT', compressed)
    iend = png_chunk(b'IEND', b'')
    return signature + ihdr + idat + iend

def distance(x1, y1, x2, y2):
    return ((x1 - x2) ** 2 + (y1 - y2) ** 2) ** 0.5

size = 192
pixels = []

PINK_BG = (255, 228, 225)
SKIN = (255, 218, 185)
WHITE = (255, 255, 255)
BLACK = (50, 50, 50)
PINK_CHEEK = (255, 182, 193)
RED_MOUTH = (255, 100, 100)
BROWN_HAIR = (139, 90, 43)

cx, cy = size // 2, size // 2
r = size // 2 - 10

for y in range(size):
    for x in range(size):
        d = distance(x, y, cx, cy)
        color = PINK_BG

        if d < r:
            color = SKIN

        if distance(x, y, cx - r * 0.7, cy - r * 0.5) < r * 0.15:
            color = SKIN
        if distance(x, y, cx + r * 0.7, cy - r * 0.5) < r * 0.15:
            color = SKIN

        if y < cy - r * 0.3 and d < r + 5:
            color = BROWN_HAIR

        eye_y = cy - r * 0.15
        for ex in [cx - r * 0.3, cx + r * 0.3]:
            ed = distance(x, y, ex, eye_y)
            if ed < r * 0.12:
                color = WHITE
            if ed < r * 0.07:
                color = BLACK
            if ed < r * 0.03 and x > ex:
                color = WHITE

        nose_y = cy + r * 0.1
        if distance(x, y, cx, nose_y) < r * 0.05:
            color = (255, 200, 180)

        mouth_y = cy + r * 0.3
        md = distance(x, y, cx, mouth_y)
        if abs(md - r * 0.2) < r * 0.03 and y > mouth_y:
            color = RED_MOUTH

        for cheek_x in [cx - r * 0.5, cx + r * 0.5]:
            cheek_y = cy + r * 0.15
            if distance(x, y, cheek_x, cheek_y) < r * 0.12:
                if color == SKIN:
                    color = PINK_CHEEK

        pixels.append(color)

png_data = create_png(size, size, pixels)

with open('/root/baby_assistant/assets/icons/app_icon.png', 'wb') as f:
    f.write(png_data)

print(f"Cute icon created: {len(png_data)} bytes, size: {size}x{size}")