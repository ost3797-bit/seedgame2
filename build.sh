#!/bin/bash
set -e

GODOT_VERSION="4.7"

echo "Downloading Godot ${GODOT_VERSION}..."
curl -sL "https://github.com/godotengine/godot/releases/download/${GODOT_VERSION}-stable/Godot_v${GODOT_VERSION}-stable_linux.x86_64.zip" -o godot.zip
unzip -q godot.zip
chmod +x Godot_v${GODOT_VERSION}-stable_linux.x86_64

echo "Downloading Export Templates..."
curl -sL "https://github.com/godotengine/godot/releases/download/${GODOT_VERSION}-stable/Godot_v${GODOT_VERSION}-stable_export_templates.tpz" -o templates.tpz
mkdir -p ~/.local/share/godot/export_templates/${GODOT_VERSION}.stable
unzip -q templates.tpz -d temp_templates
mv temp_templates/templates/* ~/.local/share/godot/export_templates/${GODOT_VERSION}.stable/

if [ ! -f "export_presets.cfg" ]; then
echo "Creating export_presets.cfg for Web Export..."
cat << 'EOF' > export_presets.cfg
[preset.0]

name="Web"
platform="Web"
runnable=true
dedicated_server=false
custom_features=""
export_filter="all_resources"
include_filter=""
exclude_filter=""
export_path="public/index.html"
encryption_include_filters=""
encryption_exclude_filters=""
encrypt_pck=false
encrypt_directory=false

[preset.0.options]

custom_template/debug=""
custom_template/release=""
variant/thread_support=false
variant/extensions_support=false
vram_texture_compression/for_desktop=true
vram_texture_compression/for_mobile=false
html/export_icon=true
html/custom_html_shell=""
html/head_include=""
html/canvas_resize_policy=2
html/focus_canvas_on_start=true
html/experimental_virtual_keyboard=false
progressive_web_app/enabled=false
progressive_web_app/offline_page=""
progressive_web_app/display=1
progressive_web_app/orientation=0
progressive_web_app/icon_144x144=""
progressive_web_app/icon_180x180=""
progressive_web_app/icon_512x512=""
progressive_web_app/background_color=Color(0, 0, 0, 1)
EOF
fi

mkdir -p public
echo "Exporting project..."
./Godot_v${GODOT_VERSION}-stable_linux.x86_64 --headless --export-release "Web" public/index.html
echo "Build complete."
