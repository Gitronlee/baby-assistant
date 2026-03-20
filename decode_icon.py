import base64
import os

b64_string = """iVBORw0KGgoAAAANSUhEUgAAAMgAAADICAYAAACtWK6eAAAABmJLR0QA/wD/AP+gvaeTAAAACXBIWXMAAAsTAAALEwEAmpwYAAAAB3RJTUUH3gkWFRYw1Yq31wAAIABJREFUeNrtfXecXFWV9u/ee6e36Z1JZtJ7h0AgvReV3lRQsYBiQcW2666767qKioqKgIqK2MFeQBEQ6UWQ3ntvBEIgPZOZ9N57u/f3x3PfzGRmMjPd3vf7fj/P88zce++9c889533P+573nHMAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA"""

output_path = '/root/baby_assistant/assets/icons/app_icon.png'
os.makedirs(os.path.dirname(output_path), exist_ok=True)

try:
    image_data = base64.b64decode(b64_string)
    with open(output_path, 'wb') as f:
        f.write(image_data)
    print(f"Icon saved to {output_path}")
    print(f"Size: {len(image_data)} bytes")
except Exception as e:
    print(f"Error: {e}")
    print(f"Base64 string length: {len(b64_string)}")
    print(f"Last 20 chars: {b64_string[-20:]}")
