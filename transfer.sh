#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 3 || $# -gt 4 ]]; then
  echo "Usage: $0 <copy|sync> <source> <destination> [--execute]" >&2
  exit 2
fi

OPERATION="$1"
SOURCE="$2"
DESTINATION="$3"
EXECUTE="${4:-}"

if [[ -n "$EXECUTE" && ( "$OPERATION" != "sync" || "$EXECUTE" != "--execute" ) ]]; then
  echo "Error: --execute is only supported for sync" >&2
  exit 2
fi

if [[ "$OPERATION" != "copy" && "$OPERATION" != "sync" ]]; then
  echo "Error: Operation must be copy or sync" >&2
  exit 2
fi

if ! command -v rclone >/dev/null 2>&1; then
  echo "Error: Rclone is not installed" >&2
  exit 1
fi

if [[ "$SOURCE" == :s3:* || "$DESTINATION" == :s3:* ]]; then
  for VAR in RCLONE_S3_PROVIDER RCLONE_S3_ACCESS_KEY_ID RCLONE_S3_SECRET_ACCESS_KEY RCLONE_S3_ENDPOINT RCLONE_S3_REGION; do
    if [[ -z "${!VAR:-}" ]]; then
      echo "Error: Missing S3 environment variable: $VAR" >&2
      echo "Configure the MinIO environment before running this script." >&2
      exit 2
    fi
  done
fi

echo "Operation: $OPERATION"
echo "Source: $SOURCE"
echo "Destination: $DESTINATION"

LOG_FILE="transfer.log"
RCLONE_ARGS=(--config /dev/null --progress --stats 5s --log-file "$LOG_FILE" --log-level INFO)

if [[ "$OPERATION" == "sync" && "$EXECUTE" != "--execute" ]]; then
  echo "Safety: Running sync in dry-run mode"
  RCLONE_ARGS+=(--dry-run)
fi

echo "Starting Rclone transfer..."

if rclone "$OPERATION" "$SOURCE" "$DESTINATION" "${RCLONE_ARGS[@]}"; then
  echo "Transfer completed successfully"
  echo "Log file: $LOG_FILE"
else
  STATUS=$?
  echo "Transfer failed with exit code: $STATUS" >&2
  exit "$STATUS"
fi
