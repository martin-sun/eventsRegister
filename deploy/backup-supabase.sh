#!/bin/bash
set -euo pipefail

# ============================================
# Supabase Database Backup Script
# Usage: ./backup-supabase.sh [options]
# ============================================

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
BACKUP_DIR="${PROJECT_DIR}/backups"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log()  { echo -e "${GREEN}[INFO]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
err()  { echo -e "${RED}[ERROR]${NC} $1"; }

# ============================================
# Load database URL
# ============================================
DB_URL=""

# Option 1: from --db-url flag
# Option 2: from SUPABASE_DB_URL env var
# Option 3: from .env.backup file
# Option 4: from supabase link (default)

load_env() {
  local env_file="${PROJECT_DIR}/.env.backup"
  if [[ -f "$env_file" ]]; then
    source "$env_file"
    if [[ -n "${SUPABASE_DB_URL:-}" ]]; then
      DB_URL="$SUPABASE_DB_URL"
    fi
  fi
}

# ============================================
# Parse arguments
# ============================================
MODE="all"  # all | schema | data
COMPRESS=true

while [[ $# -gt 0 ]]; do
  case $1 in
    --schema-only) MODE="schema"; shift ;;
    --data-only)   MODE="data"; shift ;;
    --all)         MODE="all"; shift ;;
    --db-url=*)    DB_URL="${1#*=}"; shift ;;
    --no-compress) COMPRESS=false; shift ;;
    --help)
      echo "Usage: $0 [options]"
      echo ""
      echo "Options:"
      echo "  --schema-only   Dump schema only (no data)"
      echo "  --data-only     Dump data only (no schema)"
      echo "  --all           Dump both schema and data (default)"
      echo "  --db-url=URL    PostgreSQL connection string"
      echo "  --no-compress   Skip gzip compression"
      echo "  --help          Show this help"
      echo ""
      echo "Environment variables:"
      echo "  SUPABASE_DB_URL   Database connection string"
      echo ""
      echo "Setup: Create .env.backup with:"
      echo "  SUPABASE_DB_URL=postgresql://postgres.[ref]:[password]@aws-0-[region].pooler.supabase.com:6543/postgres"
      exit 0
      ;;
    *) err "Unknown option: $1"; exit 1 ;;
  esac
done

load_env

# ============================================
# Validate
# ============================================
if ! command -v supabase &>/dev/null; then
  err "supabase CLI not found. Install: https://supabase.com/docs/guides/cli"
  exit 1
fi

if [[ -z "$DB_URL" ]]; then
  warn "No --db-url or SUPABASE_DB_URL provided, will use supabase link."
  warn "If not linked, run: supabase link --project-ref <your-project-ref>"
fi

# ============================================
# Create backup directory
# ============================================
mkdir -p "$BACKUP_DIR"

# ============================================
# Build supabase db dump command
# ============================================
DUMP_CMD="supabase db dump"
if [[ -n "$DB_URL" ]]; then
  DUMP_CMD="$DUMP_CMD --db-url $DB_URL"
fi

dump_schema() {
  local file="$BACKUP_DIR/${TIMESTAMP}_schema.sql"
  log "Dumping schema..."
  $DUMP_CMD --keep-comments -f "$file"
  if $COMPRESS; then
    gzip "$file"
    file="${file}.gz"
  fi
  log "Schema backup: $file ($(du -h "$file" | cut -f1))"
}

dump_data() {
  local file="$BACKUP_DIR/${TIMESTAMP}_data.sql"
  log "Dumping data..."
  $DUMP_CMD --data-only --use-copy -f "$file"
  # Exclude Supabase system tables
  if $COMPRESS; then
    gzip "$file"
    file="${file}.gz"
  fi
  log "Data backup: $file ($(du -h "$file" | cut -f1))"
}

# ============================================
# Run backup
# ============================================
log "Starting Supabase backup (mode: $MODE, compress: $COMPRESS)"
log "Timestamp: $TIMESTAMP"

case $MODE in
  schema) dump_schema ;;
  data)   dump_data ;;
  all)
    dump_schema
    dump_data
    ;;
esac

# ============================================
# Cleanup old backups (keep last 30 days)
# ============================================
log "Cleaning up backups older than 30 days..."
find "$BACKUP_DIR" -name "*.sql.gz" -mtime +30 -delete 2>/dev/null || true
find "$BACKUP_DIR" -name "*.sql" -mtime +30 -delete 2>/dev/null || true

log "Backup complete!"
