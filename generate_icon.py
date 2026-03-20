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

size = 256
pixels = []
pink_bg = (255, 228, 225)
skin = (255, 218, 185)
white = (255, 255, 255)
black = (50, 50, 50)
center_x, center_y = size // 2, size // 2
radius = size // 3

for y in range(size):
    for x in range(size):
        dx = x - center_x
        dy = y - center_y
        dist = (dx * dx + dy * dy) ** 0.5
        color = pink_bg

        if dist < radius:
            color = skin

        eye_y = center_y - radius // 6
        for eye_x_offset in [-radius // 3, radius // 3]:
            eye_x = center_x + eye_x_offset
            eye_dist = ((x - eye_x) ** 2 + (y - eye_y) ** 2) ** 0.5
            if eye_dist < radius // 8:
                color = black
            if eye_dist < radius // 12:
                color = white

        nose_y = center_y + radius // 8
        nose_dist = ((x - center_x) ** 2 + (y - nose_y) ** 2) ** 0.5
        if nose_dist < radius // 15:
            color = (255, 200, 180)

        smile_y = center_y + radius // 3
        smile_dist = ((x - center_x) ** 2 + (y - smile_y) ** 2) ** 0.5
        if abs(smile_dist - radius // 3) < radius // 20 and y > smile_y:
            color = (255, 100, 100)

        for blush_x_offset in [-radius // 2, radius // 2]:
            blush_x = center_x + blush_x_offset
            blush_y = center_y + radius // 6
            blush_dist = ((x - blush_x) ** 2 + (y - blush_y) ** 2) ** 0.5
            if blush_dist < radius // 5 and color == skin:
                color = (255, 200, 200)

        pixels.append(color)

png_data = create_png(size, size, pixels)

with open('/root/baby_assistant/assets/icons/app_icon.png', 'wb') as f:
    f.write(png_data)

print(f"Icon created: {len(png_data)} bytes")