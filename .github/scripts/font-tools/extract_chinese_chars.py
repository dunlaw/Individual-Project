import os
import sys
from pathlib import Path
def extract_chinese_chars_from_csv(csv_path):
    
    chinese_chars = set()
    try:
        with open(csv_path, 'r', encoding='utf-8') as f:
            content = f.read()
            for char in content:
                code_point = ord(char)
                if (0x4E00 <= code_point <= 0x9FFF or
                    0x3400 <= code_point <= 0x4DBF or
                    0xF900 <= code_point <= 0xFAFF):
                    chinese_chars.add(char)
    except Exception as e:
        print(f"Error reading {csv_path}: {e}", file=sys.stderr)
    return chinese_chars
def extract_all_chinese_chars(localization_dir):
    
    all_chars = set()
    common_punctuation = set('，。！？：；「」『』（）《》【】、""''…—')
    all_chars.update(common_punctuation)
    csv_files = list(Path(localization_dir).glob('*.csv'))
    print(f"Found {len(csv_files)} CSV files", file=sys.stderr)
    for csv_file in csv_files:
        chars = extract_chinese_chars_from_csv(csv_file)
        print(f"  {csv_file.name}: {len(chars)} unique Chinese characters", file=sys.stderr)
        all_chars.update(chars)
    return all_chars
def main():
    if len(sys.argv) != 3:
        print(__doc__)
        sys.exit(1)
    localization_dir = sys.argv[1]
    output_file = sys.argv[2]
    if not os.path.isdir(localization_dir):
        print(f"Error: Directory not found: {localization_dir}", file=sys.stderr)
        sys.exit(1)
    print(f"Extracting Chinese characters from: {localization_dir}", file=sys.stderr)
    chinese_chars = extract_all_chinese_chars(localization_dir)
    print(f"\nTotal unique Chinese characters: {len(chinese_chars)}", file=sys.stderr)
    with open(output_file, 'w', encoding='utf-8') as f:
        sorted_chars = ''.join(sorted(chinese_chars))
        f.write(sorted_chars)
    print(f"Saved character list to: {output_file}", file=sys.stderr)
    print(f"Sample: {''.join(list(sorted_chars)[:50])}", file=sys.stderr)
    return 0
if __name__ == "__main__":
    sys.exit(main())
