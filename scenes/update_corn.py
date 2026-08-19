import re

with open('MinigameCorn.tscn', 'r', encoding='utf-8') as f:
    content = f.read()

cols = 3
start_x = 396
space_x = 180
start_y = 112
space_y = 85

def repl(m):
    idx = int(m.group(1))
    c = idx % cols
    r = idx // cols
    x = start_x + c * space_x
    y = start_y + r * space_y
    node_header = m.group(0).split('\n')[0]
    return f'{node_header}\nposition = Vector2({x}, {y})\nscale = Vector2(0.8, 0.8)'

# Pattern to match [node name="CornHole_XX" type="Area2D" parent="CornSpots"]\nposition = Vector2(..., ...)
new_content = re.sub(r'\[node name="CornHole_(\d+)" type="Area2D" parent="CornSpots"\]\nposition = Vector2\([^\)]+\)', repl, content)

with open('MinigameCorn.tscn', 'w', encoding='utf-8') as f:
    f.write(new_content)
print('Done!')
