import sqlite3, os

os.makedirs("data", exist_ok=True)
db = sqlite3.connect("data/crr_memory.sqlite")
cur = db.cursor()

cur.executescript("""
CREATE TABLE IF NOT EXISTS events (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    ts DATETIME DEFAULT CURRENT_TIMESTAMP,
    source TEXT,
    event_type TEXT,
    summary TEXT,
    raw_path TEXT
);

CREATE TABLE IF NOT EXISTS zoho_crm_records (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    module TEXT,
    name TEXT,
    stage TEXT,
    owner TEXT,
    amount REAL,
    summary TEXT
);

CREATE TABLE IF NOT EXISTS zoho_mail_messages (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    sender TEXT,
    subject TEXT,
    summary TEXT
);

CREATE TABLE IF NOT EXISTS pdf_chunks (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    file_name TEXT,
    page INTEGER,
    chunk TEXT
);

CREATE TABLE IF NOT EXISTS code_findings (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    issue TEXT,
    impact TEXT,
    recommendation TEXT
);
""")

db.commit()
db.close()
print("Database ready")
