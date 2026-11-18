import hashlib
import sys
from pathlib import Path

sys.stdout.reconfigure(encoding="utf-8")
sys.path.insert(0, str(Path(__file__).parent / "python-packages"))
from pypdf import PdfReader

for filename in ["output/pdf/M5_Work_Outline.pdf", "output/pdf/RELEASE_CANDIDATE.pdf"]:
    path = Path(filename)
    reader = PdfReader(path)
    print(f"\nFILE: {filename}\nSHA256: {hashlib.sha256(path.read_bytes()).hexdigest()}")
    print(f"PAGES: {len(reader.pages)}\nMETADATA: {reader.metadata}")
    print("FIRST PAGE:\n", reader.pages[0].extract_text()[:6000])
    print("LAST PAGE:\n", reader.pages[-1].extract_text()[-2500:])
