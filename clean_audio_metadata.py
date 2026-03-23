import os
from mutagen.mp3 import MP3
from mutagen.id3 import ID3, ID3NoHeaderError
def clean_audio_files(directory):
    
    for root, dirs, files in os.walk(directory):
        for file in files:
            if file.lower().endswith('.mp3'):
                file_path = os.path.join(root, file)
                print(f"Processing: {file}")
                try:
                    audio = MP3(file_path, ID3=ID3)
                    audio.delete()
                    audio.save()
                    try:
                        tags = ID3(file_path)
                        tags.delete()
                        tags.save()
                    except ID3NoHeaderError:
                        pass
                    print(f"Successfully cleaned: {file}")
                except Exception as e:
                    print(f"Error processing {file}: {e}")
if __name__ == "__main__":
    project_root = os.path.dirname(os.path.abspath(__file__))
    target_folders = [
        os.path.join(project_root, "1.Codebase", "src", "assets", "music"),
        os.path.join(project_root, "1.Codebase", "src", "assets", "sound")
    ]
    for folder in target_folders:
        if os.path.exists(folder):
            print(f"\n--- Cleaning folder: {folder} ---")
            clean_audio_files(folder)
        else:
            print(f"\nFolder not found: {folder}")
