#!/data/data/com.termux/files/usr/bin/bash

cd ~/crr-ai-os || exit 1

mkdir -p logs outputs memory/repairs

echo "$(date) - CRR persistent agent started" >> logs/agent.log

while true; do
  echo "$(date) - Agent cycle started" >> logs/agent.log

  # 1. Sync Google Drive if rclone remote exists
  if rclone listremotes | grep -q "gdrive:"; then
    echo "$(date) - Syncing Google Drive" >> logs/agent.log
    rclone copy "gdrive:CRR Documents" ~/crr-ai-os/pdfs --progress >> logs/rclone.log 2>&1
  else
    echo "$(date) - No gdrive remote found yet" >> logs/agent.log
  fi

  # 2. Initialize database if missing
  if [ ! -f data/crr_memory.sqlite ]; then
    echo "$(date) - Database missing, rebuilding" >> logs/agent.log
    python scripts/init_db.py >> logs/db.log 2>&1
  fi

  # 3. Ingest PDFs
  if [ -f scripts/ingest_pdfs.py ]; then
    echo "$(date) - Ingesting PDFs" >> logs/agent.log
    python scripts/ingest_pdfs.py >> logs/pdf_ingestion.log 2>&1
  fi

  # 4. Ingest Zoho exports
  if [ -f scripts/ingest_zoho_exports.py ]; then
    echo "$(date) - Ingesting Zoho exports" >> logs/agent.log
    python scripts/ingest_zoho_exports.py >> logs/zoho_ingestion.log 2>&1
  fi

  # 5. Create snapshot
  {
    echo "# CRR AI OS Snapshot"
    echo
    echo "Generated: $(date)"
    echo
    echo "## Files"
    find memory scripts outputs -type f | sort
    echo
    echo "## Recent Agent Log"
    tail -n 50 logs/agent.log
  } > outputs/system_snapshot.md

  # 6. Create Codex/OpenClaw/Hermes task prompt
  cat > outputs/next_agent_task.md <<'TASK'
Read this CRR AI OS repository.

Zoho CRM and Zoho Mail are the primary source of truth.

Analyze the latest memory, PDFs, Zoho exports, logs, and system snapshot.

Create:
1. missed revenue findings
2. SOP improvements
3. follow-up gaps
4. software improvement ideas
5. next recommended actions

Do not send messages, update CRM records, move money, or change production systems without human approval.
TASK

  # 7. Auto commit and push
  git add .
  git commit -m "Agent cycle update" >> logs/git.log 2>&1
  git push >> logs/git.log 2>&1

  echo "$(date) - Agent cycle complete" >> logs/agent.log

  # Run every 15 minutes
  sleep 900
done
