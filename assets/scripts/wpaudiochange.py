#!/usr/bin/env python 
import subprocess

def parse_wpctl_status():
    output = str(subprocess.check_output("wpctl status", shell=True, encoding='utf-8'))
    lines = output.replace("├", "").replace("─", "").replace("│", "").replace("└", "").splitlines()

    sinks_index = None
    for index, line in enumerate(lines):
        if "Sinks:" in line:
            sinks_index = index
            break

    sinks = []
    for line in lines[sinks_index + 1:]:
        if not line.strip():
            break
        sinks.append(line.strip())

    for index, sink in enumerate(sinks):
        sinks[index] = sink.split("[vol:")[0].strip()
    
    for index, sink in enumerate(sinks):
        if sink.startswith("*"):
            sinks[index] = sink.strip().replace("*", "").strip() + " - Default"

    sinks_dict = [{"sink_id": int(sink.split(".")[0]), "sink_name": sink.split(".")[1].strip()} for sink in sinks]

    return sinks_dict

output = ''
sinks = parse_wpctl_status()
for items in sinks:
    if items['sink_name'].endswith(" - Default"):
        output += f"<b>-> {items['sink_name']}</b>\n"
    else:
        output += f"{items['sink_name']}\n"

wofi_command = f"echo '{output}' | wofi --show=dmenu --hide-scroll --allow-markup --define=hide_search=true --location=bottom_left --width=600 --height=200 --xoffset=20 --yoffset=-90"
wofi_process = subprocess.run(wofi_command, shell=True, encoding='utf-8', stdout=subprocess.PIPE, stderr=subprocess.PIPE)

if wofi_process.returncode != 0:
    print("User cancelled the operation.")
    exit(0)

selected_sink_name = wofi_process.stdout.strip()

# Debug: Print selected sink name
print(f"Selected sink name: '{selected_sink_name}'")

# Remove "- Default" suffix if present
selected_sink_name = selected_sink_name.replace(" - Default", "").strip()

# Debug: Print sinks
print("Available sinks:")
for sink in sinks:
    print(f"  {sink['sink_name']}")

# More forgiving selection logic
try:
    selected_sink = next(sink for sink in sinks if selected_sink_name in sink['sink_name'])
except StopIteration:
    print(f"No matching sink found for '{selected_sink_name}'")
    print("Available sinks:")
    for sink in sinks:
        print(f"  {sink['sink_name']}")
    exit(1)

# Debug: Print selected sink
print(f"Matched sink: {selected_sink}")

subprocess.run(f"wpctl set-default {selected_sink['sink_id']}", shell=True)
print(f"Set default sink to: {selected_sink['sink_name']} (ID: {selected_sink['sink_id']})")
