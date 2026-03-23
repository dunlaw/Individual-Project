import csv
import time
from deep_translator import GoogleTranslator

input_file = '1.Codebase/localization/gda1_translations.csv'
output_file = '1.Codebase/localization/gda1_translations.csv'

def translate_file():
    translator = GoogleTranslator(source='en', target='de')
    
    print(f"Reading {input_file}...")
    with open(input_file, mode='r', encoding='utf-8') as f:
        reader = list(csv.reader(f))
    
    header = reader[0]
    en_idx = header.index('en')
    de_idx = header.index('de')
    
    rows = reader[1:]
    total = len(rows)
    translated_count = 0
    
    print(f"Total lines to process: {total}")

    for i, row in enumerate(rows):
        if not row:
            continue
            
        # Skip comments or empty keys
        if not row[0].strip() or row[0].startswith('#'):
            continue
            
        en_text = row[en_idx]
        # Only translate if the current German column is empty or still contains the English placeholder
        # In the previous step I filled 'de' with 'en' text, so we check if de == en
        if en_text.strip() and (len(row) <= de_idx or row[de_idx] == en_text):
            try:
                translated = translator.translate(en_text)
                if len(row) <= de_idx:
                    row.append(translated)
                else:
                    row[de_idx] = translated
                
                translated_count += 1
                if translated_count % 20 == 0:
                    print(f"Translated {translated_count} items (Line {i+1}/{total})...")
                    # Small sleep to be nice to the API
                    time.sleep(0.5)
            except Exception as e:
                print(f"Error on line {i+1} ('{en_text}'): {e}")
                time.sleep(2) # Longer sleep on error
    
    print(f"Writing results to {output_file}...")
    with open(output_file, mode='w', encoding='utf-8', newline='') as f:
        writer = csv.writer(f)
        writer.writerow(header)
        writer.writerows(rows)
    
    print(f"Done! Translated {translated_count} new items.")

if __name__ == "__main__":
    translate_file()
