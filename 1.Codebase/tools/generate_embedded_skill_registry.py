#!/usr/bin/env python3
"""Generate embedded_skill_registry.gd from skill SKILL.md files.

Usage:
    python tools/generate_embedded_skill_registry.py

This reads all SKILL.md files from src/skills/ and produces
generated/embedded_skill_registry.gd — a GDScript file that the
SkillManager can load as a fallback when filesystem-based directory
scanning is unavailable (e.g. web / HTML5 exports).
"""
import os
import sys

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
CODEBASE_DIR = os.path.dirname(SCRIPT_DIR)
SKILLS_DIR = os.path.join(CODEBASE_DIR, "src", "skills")
OUTPUT_FILE = os.path.join(CODEBASE_DIR, "generated", "embedded_skill_registry.gd")

# filename -> language code
LANG_MAP = {
    "SKILL.md": "en",
    "SKILL.de.md": "de",
    "SKILL.zh.md": "zh",
}


def parse_frontmatter(content):
    """Parse YAML-like frontmatter and return (metadata_dict, body_text)."""
    if not content.startswith("---"):
        return {}, content
    end_marker = content.find("\n---", 3)
    if end_marker == -1:
        return {}, content
    frontmatter_str = content[4:end_marker].strip()
    body = content[end_marker + 5:].strip()

    result = {}
    current_key = ""
    in_array = False
    array_items = []

    for line in frontmatter_str.split("\n"):
        stripped = line.strip()
        if not stripped:
            continue
        if in_array:
            if stripped.startswith("- "):
                array_items.append(stripped[2:].strip())
            else:
                result[current_key] = array_items
                in_array = False
                array_items = []
        if not in_array:
            colon_pos = stripped.find(":")
            if colon_pos > 0:
                current_key = stripped[:colon_pos].strip()
                value = stripped[colon_pos + 1:].strip()
                if not value:
                    in_array = True
                    array_items = []
                else:
                    result[current_key] = value
    if in_array and array_items:
        result[current_key] = array_items

    return result, body


def escape_gdscript_string(s):
    """Escape a string for embedding in a GDScript double-quoted literal."""
    s = s.replace("\\", "\\\\")
    s = s.replace('"', '\\"')
    s = s.replace("\n", "\\n")
    s = s.replace("\t", "\\t")
    s = s.replace("\r", "")
    return s


def generate_registry():
    if not os.path.isdir(SKILLS_DIR):
        print(f"ERROR: Skills directory not found: {SKILLS_DIR}", file=sys.stderr)
        sys.exit(1)

    skills = {}

    for skill_folder in sorted(os.listdir(SKILLS_DIR)):
        skill_path = os.path.join(SKILLS_DIR, skill_folder)
        if not os.path.isdir(skill_path) or skill_folder.startswith("."):
            continue

        main_file = os.path.join(skill_path, "SKILL.md")
        if not os.path.exists(main_file):
            print(f"  SKIP {skill_folder}/ — no SKILL.md found", file=sys.stderr)
            continue

        with open(main_file, "r", encoding="utf-8") as f:
            content = f.read()

        metadata, en_body = parse_frontmatter(content)
        if not metadata:
            print(f"  SKIP {skill_folder}/ — no frontmatter in SKILL.md", file=sys.stderr)
            continue

        skill_name = metadata.get("name", skill_folder)
        skill_content = {"en": en_body}

        for filename, lang in LANG_MAP.items():
            if lang == "en":
                continue
            lang_file = os.path.join(skill_path, filename)
            if os.path.exists(lang_file):
                with open(lang_file, "r", encoding="utf-8") as f:
                    lang_content = f.read()
                _, lang_body = parse_frontmatter(lang_content)
                if lang_body:
                    skill_content[lang] = lang_body

        skills[skill_name] = {
            "name": skill_name,
            "description": metadata.get("description", ""),
            "folder": skill_folder,
            "purpose_triggers": metadata.get("purpose_triggers", []),
            "content": skill_content,
        }

    # Build GDScript output
    lines = [
        "# AUTO-GENERATED FILE — do not edit manually.",
        "# Regenerate with: python tools/generate_embedded_skill_registry.py",
        "# This file embeds all skill metadata and content for platforms",
        "# where filesystem-based skill scanning is unavailable (e.g. web builds).",
        "",
        "",
        "static func get_skills() -> Dictionary:",
        "\treturn {",
    ]

    for skill_name, skill_data in skills.items():
        lines.append('\t\t"%s": {' % escape_gdscript_string(skill_name))
        lines.append('\t\t\t"name": "%s",' % escape_gdscript_string(skill_data["name"]))
        lines.append('\t\t\t"description": "%s",' % escape_gdscript_string(skill_data["description"]))
        lines.append('\t\t\t"folder": "%s",' % escape_gdscript_string(skill_data["folder"]))

        triggers = skill_data.get("purpose_triggers", [])
        if isinstance(triggers, list):
            trigger_strs = ", ".join('"%s"' % escape_gdscript_string(t) for t in triggers)
            lines.append('\t\t\t"purpose_triggers": [%s],' % trigger_strs)
        else:
            lines.append('\t\t\t"purpose_triggers": [],')

        lines.append('\t\t\t"content": {')
        for lang, body in skill_data["content"].items():
            escaped = escape_gdscript_string(body)
            lines.append('\t\t\t\t"%s": "%s",' % (lang, escaped))
        lines.append("\t\t\t},")
        lines.append("\t\t},")

    lines.append("\t}")
    lines.append("")

    os.makedirs(os.path.dirname(OUTPUT_FILE), exist_ok=True)
    with open(OUTPUT_FILE, "w", encoding="utf-8") as f:
        f.write("\n".join(lines))

    print(f"Generated {OUTPUT_FILE} with {len(skills)} skills")
    for name in sorted(skills.keys()):
        langs = list(skills[name]["content"].keys())
        print(f"  - {name} ({', '.join(langs)})")


if __name__ == "__main__":
    generate_registry()
