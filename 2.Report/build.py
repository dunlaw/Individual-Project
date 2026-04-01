"""
build.py  –  Count words in Final_Report.tex then run pdflatex three times.

Word-count rules mirror the %TC:envir directives in the .tex file:
  excluded: figure, table, tabular, lstlisting environments
  excluded: % comments
Invoke:  python build.py
"""
import re
import subprocess
import sys
from pathlib import Path

TEX_FILE = Path(__file__).parent / "Final_Report.tex"
OUT_FILE = Path(__file__).parent / "wordcount.txt"

PDFLATEX = r"C:\Users\dunc4\AppData\Local\Programs\MiKTeX\miktex\bin\x64\pdflatex.exe"

# ---------------------------------------------------------------------------
# 1.  Word count
# ---------------------------------------------------------------------------
EXCLUDED_ENVS = ["figure", "table", "tabular", "lstlisting"]

text = TEX_FILE.read_text(encoding="utf-8")
# Exclude appendix from word count
appendix_pos = text.find(r"\appendix")
if appendix_pos > 0:
    text = text[:appendix_pos]

# Strip excluded environments (those with %TC:envir ... 0 0)
for env in EXCLUDED_ENVS:
    text = re.sub(
        r"\\begin\{" + env + r"\*?\}.*?\\end\{" + env + r"\*?\}",
        "",
        text,
        flags=re.DOTALL,
    )

# Strip LaTeX comments
text = re.sub(r"(?m)(?<!\\)%.*$", "", text)

# Strip \command[...]{...} constructs but keep the text inside {}
# First remove optional args
text = re.sub(r"\\[a-zA-Z]+\*?(\[[^\]]*\])?", " ", text)
# Remove remaining braces but keep content
text = re.sub(r"[{}]", " ", text)

# Count tokens that start with at least one letter (exclude pure numbers / symbols)
words = [w for w in text.split() if re.match(r"[A-Za-z]", w)]
count = len(words)

OUT_FILE.write_text(str(count) + "\n")
print(f"Word count written: {count}")

# ---------------------------------------------------------------------------
# 2.  Three pdflatex passes
# ---------------------------------------------------------------------------
for pass_num in range(1, 4):
    print(f"\n=== pdflatex pass {pass_num}/3 ===")
    result = subprocess.run(
        [
            PDFLATEX,
            "-interaction=nonstopmode",
            "-shell-escape",
            "Final_Report.tex",
        ],
        cwd=Path(__file__).parent,
    )
    if result.returncode not in (0, 1):  # 1 = warnings only
        print(f"pdflatex exited with code {result.returncode}", file=sys.stderr)

print("\nDone. Output: Final_Report.pdf")
