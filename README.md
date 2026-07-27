# CRR AI Operating System

CRR AI OS is an early-stage, local-first operations data pipeline for collecting business information in one repository so an AI agent can later analyze it for revenue opportunities, follow-up gaps, process improvements, and software recommendations.

The intended business systems of record are Zoho CRM and Zoho Mail. The current implementation, however, only initializes a local SQLite database, optionally downloads PDFs from Google Drive with `rclone`, extracts text from those PDFs, and prepares a snapshot and task prompt for a separate agent such as Codex, OpenClaw, or Hermes.

> **Project status:** Prototype/scaffold. Zoho ingestion, financial-data ingestion, and automated AI analysis are planned but are not implemented in this repository.

## What it currently does

The persistent shell loop is designed to run in Termux on Android every 15 minutes. Each cycle:

1. Checks for an `rclone` remote named `gdrive:`.
2. Copies files from `gdrive:CRR Documents` into a local `pdfs/` directory.
3. Creates the SQLite database if it does not exist.
4. Extracts text from every PDF and stores up to 1,000 characters from each page in SQLite.
5. Looks for a future `scripts/ingest_zoho_exports.py` script and runs it if present.
6. Regenerates a repository snapshot in `outputs/system_snapshot.md`.
7. Regenerates an agent assignment in `outputs/next_agent_task.md`.
8. Commits and pushes all repository changes to Git.

The generated agent assignment asks a separate AI agent to review the repository and produce:

- missed-revenue findings;
- SOP improvements;
- follow-up gaps;
- software improvement ideas; and
- recommended next actions.

The repository's operating rule is read-only analysis first. Messages, CRM updates, financial actions, and production-system changes require human approval.

## What it does not yet do

- Connect to the Zoho CRM or Zoho Mail APIs.
- Import Zoho exports because `scripts/ingest_zoho_exports.py` does not yet exist.
- Call an AI model or automatically generate business findings.
- Ingest financial data, code findings, or staff interviews.
- Deduplicate PDF pages between cycles.
- Track changed or deleted source documents.
- Encrypt the SQLite database or manage secrets.
- Provide a web interface, API, tests, or deployment configuration.

## Architecture

```text
Google Drive: CRR Documents
             |
             | rclone copy
             v
          pdfs/*.pdf
             |
             | pypdf extraction
             v
     data/crr_memory.sqlite
             |
             +-----------------------------+
                                           |
memory/*.md + logs/*.log + scripts/*        |
             |                             |
             +-------------+---------------+
                           |
                           v
             outputs/system_snapshot.md
             outputs/next_agent_task.md
                           |
                           v
              External AI agent review
```

## Repository layout

```text
.
├── AGENTS.md                         # Mission and human-approval rules
├── data/
│   └── crr_memory.sqlite             # Local structured memory
├── logs/                             # Loop, PDF, and rclone logs
├── memory/
│   ├── decisions/decision_log.md     # Placeholder for decisions
│   ├── repairs/repair_history.md     # Placeholder for repair history
│   ├── system_state.md               # Sources and operating mode
│   └── zoho/zoho_master_plan.md      # Planned Zoho analysis scope
├── outputs/
│   ├── next_agent_task.md            # Prompt for a separate AI agent
│   └── system_snapshot.md            # Generated file and log snapshot
└── scripts/
    ├── crr_agent_loop.sh             # Persistent 15-minute Termux loop
    ├── ingest_pdfs.py                # PDF-to-SQLite ingestion
    └── init_db.py                    # SQLite schema initialization
```

The tracked `main` file is currently empty.

## SQLite data model

`scripts/init_db.py` creates five tables:

| Table | Purpose | Current writer |
| --- | --- | --- |
| `events` | General timestamped events | Not implemented |
| `zoho_crm_records` | CRM module, stage, owner, amount, and summary | Not implemented |
| `zoho_mail_messages` | Email sender, subject, and summary | Not implemented |
| `pdf_chunks` | Extracted PDF page text | `scripts/ingest_pdfs.py` |
| `code_findings` | Issue, impact, and recommendation | Not implemented |

## Requirements

For the Python scripts:

- Python 3
- [`pypdf`](https://pypi.org/project/pypdf/)

For the persistent automation loop:

- Termux or another Bash environment
- Git
- `rclone`
- A configured Google Drive remote named `gdrive:`
- Push access to the configured Git remote

## Manual setup

Clone the repository and enter it:

```bash
git clone https://github.com/khemia0101-del/crr-ai-os.git
cd crr-ai-os
```

Install the Python dependency:

```bash
python -m pip install pypdf
```

Create the expected directories:

```bash
mkdir -p data pdfs logs outputs memory/repairs
```

Initialize the database:

```bash
python scripts/init_db.py
```

To test PDF ingestion, place one or more `.pdf` files in `pdfs/`, then run:

```bash
python scripts/ingest_pdfs.py
```

## Google Drive configuration

The automation expects an `rclone` remote named `gdrive:` and a Drive folder named `CRR Documents`.

Configure and verify the remote:

```bash
rclone config
rclone listremotes
rclone lsf "gdrive:CRR Documents"
```

Do not commit OAuth tokens, service-account credentials, or other secrets to this repository.

## Running the persistent loop

The script uses the Termux Bash path and expects the checkout at `~/crr-ai-os`:

```bash
chmod +x scripts/crr_agent_loop.sh
./scripts/crr_agent_loop.sh
```

Stop it with `Ctrl+C`.

### Important warning

The loop runs `git add .`, `git commit`, and `git push` every 15 minutes. This can upload PDFs, database contents, logs, generated files, or other sensitive business data if they are present and not ignored.

Before running the loop:

1. Add an appropriate `.gitignore`.
2. Decide which business data may legally and safely be committed.
3. Confirm the Git remote and account permissions.
4. Review the loop's automatic commit-and-push behavior.
5. Back up the SQLite database.

For safer development, remove or disable the Git commands on lines 70–72 of `scripts/crr_agent_loop.sh` until the repository's data-handling policy is established.

## Known limitations

- PDF ingestion is not idempotent: every run inserts the same pages again.
- Only the first 1,000 characters of each page are retained.
- The page number stored in SQLite is zero-based.
- The PDF directory must already exist when `ingest_pdfs.py` is run directly.
- A malformed or encrypted PDF can stop the ingestion run because errors are not handled per file.
- `rclone copy` does not remove local files deleted from Google Drive.
- The loop continues after failed sync or ingestion commands because strict Bash error handling is not enabled.
- Logs, generated outputs, and the SQLite database are currently tracked by Git.
- The current tracked database contains the schema but no business records.
- The included rclone log shows that the existing Google Drive credential configuration needs repair.

## Recommended next development steps

1. Add `.gitignore`, dependency pinning, and environment-based configuration.
2. Remove automatic Git publication from the ingestion loop or make it explicitly opt-in.
3. Make PDF ingestion idempotent with file hashes and page-level uniqueness.
4. Add error handling, structured logging, and automated tests.
5. Implement read-only Zoho CRM and Zoho Mail ingestion with least-privilege credentials.
6. Add provenance and timestamps to every imported record.
7. Implement a separate analysis command that reads the database and writes reviewable findings.
8. Add explicit human approval gates before any external write action.

## Security and data governance

This project is intended to process customer, email, CRM, document, and financial information. Treat the repository and its database as sensitive. Keep credentials outside Git, minimize collected personal data, restrict repository access, define retention rules, and require human review before acting on any generated recommendation.

## License

No license file is currently included. Unless the owner adds one, the repository should be treated as all rights reserved.
