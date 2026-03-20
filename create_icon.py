import struct
import zlib

def create_png(width, height, pixels):
    """Create a PNG file from pixel data"""
    def png_chunk(chunk_type, data):
        chunk_len = struct.pack('>I', len(data))
        chunk_crc = struct.pack('>I', zlib.crc32(chunk_type + data) & 0xffffffff)
        return chunk_len + chunk_type + data + chunk_crc

    # PNG signature
    signature = b'\x89PNG\r\n\x1a\n'

    # IHDR chunk
    ihdr_data = struct.pack('>IIBBBBB', width, height, 8, 2, 0, 0, 0)
    ihdr = png_chunk(b'IHDR', ihdr_data)

    # IDAT chunk (image data)
    raw_data = b''
    for y in range(height):
        raw_data += b'\x00'  # filter type
        for x in range(width):
            raw_data += bytes(pixels[y * width + x])
    compressed = zlib.compress(raw_data, 9)
    idat = png_chunk(b'IDAT', compressed)

    # IEND chunk
    iend = png_chunk(b'IEND', b'')

    return signature + ihdr + idat + iend

# Create a simple baby-themed icon (pink background with cute face)
size = 1024
pixels = []

# Colors
pink_bg = (255, 182, 193)  # #FFB6C1
skin = (255, 218, 185)  # Peach
white = (255, 255, 255)
black = (50, 50, 50)
blush = (255, 182, 193)

center_x, center_y = size // 2, size // 2
radius = size // 3

for y in range(size):
    for x in range(size):
        # Calculate distance from center
        dx = x - center_x
        dy = y - center_y
        dist = (dx * dx + dy * dy) ** 0.5

        # Background
        color = pink_bg

        # Face circle
        if dist < radius:
            color = skin

        # Left eye
        eye_x, eye_y = center_x - radius // 3, center_y - radius // 6
        eye_dist = ((x - eye_x) ** 2 + (y - eye_y) ** 2) ** 0.5
        if eye_dist < radius // 8:
            color = black
        if eye_dist < radius // 12:
            color = white

        # Right eye
        eye_x2, eye_y2 = center_x + radius // 3, center_y - radius // 6
        eye_dist2 = ((x - eye_x2) ** 2 + (y - eye_y2) ** 2) ** 0.5
        if eye_dist2 < radius // 8:
            color = black
        if eye_dist2 < radius // 12:
            color = white

        # Nose
        nose_y = center_y + radius // 8
        nose_dist = ((x - center_x) ** 2 + (y - nose_y) ** 2) ** 0.5
        if nose_dist < radius // 15:
            color = (255, 200, 180)

        # Smile
        smile_y = center_y + radius // 3
        smile_dist = ((x - center_x) ** 2 + (y - smile_y) ** 2) ** 0.5
        if abs(smile_dist - radius // 3) < radius // 20 and y > smile_y:
            color = (255, 100, 100)

        # Blush (left)
        blush_x, blush_y = center_x - radius // 2, center_y + radius // 6
        blush_dist = ((x - blush_x) ** 2 + (y - blush_y) ** 2) ** 0.5
        if blush_dist < radius // 5:
            color = (255, 200, 200) if color == skin else color

        # Blush (right)
        blush_x2, blush_y2 = center_x + radius // 2, center_y + radius // 6
        blush_dist2 = ((x - blush_x2) ** 2 + (y - blush_y2) ** 2) ** 0.5
        if blush_dist2 < radius // 5:
            color = (255, 200, 200) if color == skin else color

        # Ears
        ear_y = center_y - radius // 2
        ear_dist1 = ((x - (center_x - radius)) ** 2 + (y - ear_y) ** 2) ** 0.5
        ear_dist2 = ((x - (center_x + radius)) ** 2 + (y - ear_y) ** 2) ** 0.5
        if ear_dist1 < radius // 4 or ear_dist2 < radius // 4:
            color = skin

        pixels.append(color)

png_data = create_png(size, size, pixels)

# Save to file
with open('/root/baby_assistant/assets/icons/app_icon.png', 'wb') as f:
    f.write(png_data)

print("Icon created successfully!")
print(f"Size: {len(png_data)} bytes")
