from fontTools.subset import Subsetter, Options
from fontTools.ttLib import TTFont
import sys
import os
def subset_font(input_font, output_font, text_file):
    
    if not os.path.exists(input_font):
        print(f"Error: Input font not found: {input_font}", file=sys.stderr)
        return False
    if not os.path.exists(text_file):
        print(f"Error: Character file not found: {text_file}", file=sys.stderr)
        return False
    with open(text_file, 'r', encoding='utf-8') as f:
        text = f.read()
    chars = set(text)
    unicodes = [ord(char) for char in chars if char.strip() and ord(char) > 32]
    print(f"Subsetting font with {len(unicodes)} unique characters...", file=sys.stderr)
    font = TTFont(input_font)
    options = Options()
    options.layout_features = ['*']  
    options.notdef_outline = True   
    options.name_IDs = ['*']        
    options.name_legacy = True
    options.name_languages = ['*']
    subsetter = Subsetter(options=options)
    subsetter.populate(unicodes=unicodes)
    subsetter.subset(font)
    font.save(output_font)
    font.close()
    print(f"Font subset saved to: {output_font}", file=sys.stderr)
    original_size = os.path.getsize(input_font)
    subset_size = os.path.getsize(output_font)
    reduction = (1 - subset_size / original_size) * 100
    print(f"Original size: {original_size / 1024 / 1024:.2f} MB", file=sys.stderr)
    print(f"Subset size: {subset_size / 1024 / 1024:.2f} MB", file=sys.stderr)
    print(f"Size reduction: {reduction:.1f}%", file=sys.stderr)
    return True
def main():
    if len(sys.argv) != 4:
        print(__doc__)
        sys.exit(1)
    input_font = sys.argv[1]
    output_font = sys.argv[2]
    text_file = sys.argv[3]
    try:
        success = subset_font(input_font, output_font, text_file)
        sys.exit(0 if success else 1)
    except Exception as e:
        print(f"Error: {e}", file=sys.stderr)
        import traceback
        traceback.print_exc()
        sys.exit(1)
if __name__ == "__main__":
    main()
