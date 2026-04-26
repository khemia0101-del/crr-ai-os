import os, sqlite3
from pypdf import PdfReader

db = sqlite3.connect("data/crr_memory.sqlite")
cur = db.cursor()

for file in os.listdir("pdfs"):
    if file.endswith(".pdf"):
        reader = PdfReader(f"pdfs/{file}")
        for i, page in enumerate(reader.pages):
            text = page.extract_text() or ""
            cur.execute(
                "INSERT INTO pdf_chunks (file_name, page, chunk) VALUES (?, ?, ?)",
                (file, i, text[:1000])
            )

db.commit()
db.close()
print("PDFs ingested")
