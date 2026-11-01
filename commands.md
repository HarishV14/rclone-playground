# Rclone Commands

## Local environment
Platform: macOS
Rclone version: v1.73.0

## Create sample files
```bash
mkdir -p samples/source/{documents,videos,backups} samples/destination
echo "Welcome to Rclone Learning" > samples/source/documents/readme.txt
echo "Testpress Backup Data" > samples/source/backups/backup.txt
mkfile 100m samples/source/videos/test-video.bin
find samples -type f
du -h samples/source/videos/test-video.bin
```

## List files
```bash
rclone ls samples/source
```

## Copy files
```bash
rclone copy samples/source samples/destination --progress
echo "This is a newly added file" > samples/source/documents/new-file.txt
rclone copy samples/source samples/destination --progress
echo "Updated content for Rclone testing" > samples/source/documents/readme.txt
rclone copy samples/source samples/destination --progress
echo "Old backup file" > samples/destination/old-backup.txt
rclone copy samples/source samples/destination --progress
```

## Move files
```bash
mkdir -p samples/move-source samples/move-destination
echo "This file will be moved using Rclone" > samples/move-source/move-test.txt
rclone move samples/move-source samples/move-destination --progress
find samples/move-source samples/move-destination -type f
```

## Synchronize files
```bash
rclone sync samples/source samples/destination --dry-run
rclone sync samples/source samples/destination --progress
```

## Verify files
```bash
rclone check samples/source samples/destination
```

## Delete files
```bash
mkdir -p samples/delete-test
echo "Temporary file" > samples/delete-test/temp.txt
rclone delete samples/delete-test --progress
ls -la samples/delete-test
```

## MinIO with Docker Compose

### Start MinIO

```bash
docker compose config --quiet
docker compose up -d
docker compose ps
```

### Check MinIO readiness

```bash
curl -i http://localhost:9000/minio/health/ready
```

Expected response: HTTP/1.1 200 OK.

### Inspect container logs

```bash
docker compose logs --tail=40 minio
```

## S3 operations with MinIO (config-free)

Load MinIO credentials from the local environment file:

```bash
set -a; source .env; set +a
```

Export Rclone S3 settings for the current shell:

```bash
export RCLONE_S3_PROVIDER=Minio RCLONE_S3_ACCESS_KEY_ID="$MINIO_ROOT_USER" RCLONE_S3_SECRET_ACCESS_KEY="$MINIO_ROOT_PASSWORD" RCLONE_S3_ENDPOINT=http://127.0.0.1:9000 RCLONE_S3_REGION=us-east-1
```

All commands below use the direct :s3: backend and bypass rclone.conf with --config /dev/null.

### Create and list buckets

```bash
rclone mkdir :s3:testpress-source --config /dev/null
rclone mkdir :s3:testpress-backup --config /dev/null
rclone lsd :s3: --config /dev/null
```

### Upload, verify, and download

```bash
rclone copy samples/source :s3:testpress-source --config /dev/null --progress
rclone check samples/source :s3:testpress-source --config /dev/null
rclone copy :s3:testpress-source samples/s3-download --config /dev/null --progress
rclone check samples/source samples/s3-download
```

### Bucket-to-bucket server-side copy

```bash
rclone copy :s3:testpress-source :s3:testpress-backup --config /dev/null --progress
rclone check :s3:testpress-source :s3:testpress-backup --config /dev/null
```

### Delete a temporary S3 object and verify

```bash
printf "Temporary S3 deletion test\\n" | rclone rcat :s3:testpress-backup/delete-test.txt --config /dev/null
rclone deletefile :s3:testpress-backup/delete-test.txt --config /dev/null
rclone check :s3:testpress-source :s3:testpress-backup --config /dev/null
```

Never commit .env or credentials. For production, use scoped credentials, a secrets manager, and HTTPS.

## Large-file transfers and reliability

These commands assume the RCLONE_S3_* environment variables are exported as described above.

### Create a 1 GiB test file

```bash
mkfile 1g samples/source/videos/large-test.bin
ls -lh samples/source/videos/large-test.bin
```

### Upload with bandwidth and retry settings

```bash
rclone copyto samples/source/videos/large-test.bin :s3:testpress-source/videos/large-test.bin --config /dev/null --transfers 2 --checkers 4 --bwlimit 10M --progress --stats 5s --retries 3 --low-level-retries 5
```

Repeat the command to test skipping unchanged files.

### Interrupted upload and restart

```bash
rclone copyto samples/source/videos/large-test.bin :s3:testpress-source/videos/interrupted-test.bin --config /dev/null --bwlimit 5M --progress --stats 5s --retries 3
```

Interrupt with Ctrl+C at approximately 10-20%, then inspect the destination:

```bash
rclone ls :s3:testpress-source/videos/interrupted-test.bin --config /dev/null
```

Restart the upload:

```bash
rclone copyto samples/source/videos/large-test.bin :s3:testpress-source/videos/interrupted-test.bin --config /dev/null --bwlimit 10M --progress --stats 5s --retries 3
```

Compare the file checksums:

```bash
rclone md5sum samples/source/videos/large-test.bin
rclone md5sum :s3:testpress-source/videos/interrupted-test.bin --config /dev/null
```

### Concurrency and bandwidth comparison

```bash
mkdir -p samples/concurrency-test
for i in 1 2 3 4; do mkfile 20m "samples/concurrency-test/file-$i.bin"; done
rclone copy samples/concurrency-test :s3:testpress-source/concurrency-test-1 --config /dev/null --transfers 1 --bwlimit 5M --progress --stats 5s
rclone copy samples/concurrency-test :s3:testpress-source/concurrency-test-4 --config /dev/null --transfers 4 --bwlimit 5M --progress --stats 5s
rclone copy samples/concurrency-test :s3:testpress-source/concurrency-test-unlimited --config /dev/null --transfers 4 --progress --stats 1s
rclone check samples/concurrency-test :s3:testpress-source/concurrency-test-unlimited --config /dev/null
```

## Phase 7 - Reusable Transfer Script and Sync Safety

### Environment setup
Load .env and export RCLONE_S3_PROVIDER, RCLONE_S3_ACCESS_KEY_ID, RCLONE_S3_SECRET_ACCESS_KEY, RCLONE_S3_ENDPOINT and RCLONE_S3_REGION as shown in Phase 5.

### Script commands
```bash
chmod +x transfer.sh
./transfer.sh copy samples/concurrency-test :s3:testpress-backup/script-test
./transfer.sh copy samples/does-not-exist :s3:testpress-backup/error-test
printf "This file should survive the dry run\n" | rclone rcat :s3:testpress-backup/script-test/keep-test.txt --config /dev/null
./transfer.sh sync samples/concurrency-test :s3:testpress-backup/script-test
rclone ls :s3:testpress-backup/script-test/keep-test.txt --config /dev/null
./transfer.sh sync samples/concurrency-test :s3:testpress-backup/script-test --execute
rclone check samples/concurrency-test :s3:testpress-backup/script-test --config /dev/null
```

### Missing credentials and local copy
```bash
env -u RCLONE_S3_PROVIDER -u RCLONE_S3_ACCESS_KEY_ID -u RCLONE_S3_SECRET_ACCESS_KEY -u RCLONE_S3_ENDPOINT -u RCLONE_S3_REGION ./transfer.sh copy samples/concurrency-test :s3:testpress-backup/script-test
env -u RCLONE_S3_PROVIDER -u RCLONE_S3_ACCESS_KEY_ID -u RCLONE_S3_SECRET_ACCESS_KEY -u RCLONE_S3_ENDPOINT -u RCLONE_S3_REGION ./transfer.sh copy samples/concurrency-test samples/local-script-test
```

### Explicit S3 flags and endpoint switching
```bash
env -u RCLONE_S3_PROVIDER -u RCLONE_S3_ACCESS_KEY_ID -u RCLONE_S3_SECRET_ACCESS_KEY -u RCLONE_S3_ENDPOINT -u RCLONE_S3_REGION rclone lsd :s3: --config /dev/null --s3-provider Minio --s3-access-key-id "$MINIO_ROOT_USER" --s3-secret-access-key "$MINIO_ROOT_PASSWORD" --s3-endpoint http://127.0.0.1:9000 --s3-region us-east-1
rclone lsd :s3: --config /dev/null --s3-provider Minio --s3-access-key-id "$MINIO_ROOT_USER" --s3-secret-access-key "$MINIO_ROOT_PASSWORD" --s3-endpoint http://127.0.0.1:9999 --s3-region us-east-1 --retries 1 --low-level-retries 1
```

Warning: sync --execute deletes destination-only files. Avoid exposing credentials in process listings.

## Fresh-Clone Reproducibility Test

Clone into a separate directory and enter it:

```bash
git clone https://github.com/HarishV14/rclone-playground.git rclone-fresh-test
cd rclone-fresh-test
```

Create .env from .env.example and replace the placeholder credentials with credentials for your MinIO server. For the test against an existing local MinIO server, the same credentials must be used.

Generate four portable 1 MiB sample files using Python 3:

```bash
python3 -c 'from pathlib import Path; p=Path("samples/concurrency-test"); p.mkdir(parents=True, exist_ok=True); [(p / f"file-{i}.bin").write_bytes(bytes([i]) * (1024 * 1024)) for i in range(1, 5)]; print("Created 4 sample files (1 MiB each)")'
```

Load the local MinIO credentials and configure Rclone:

```bash
set -a; source .env; set +a
export RCLONE_S3_PROVIDER=Minio RCLONE_S3_ACCESS_KEY_ID="$MINIO_ROOT_USER" RCLONE_S3_SECRET_ACCESS_KEY="$MINIO_ROOT_PASSWORD" RCLONE_S3_ENDPOINT=http://127.0.0.1:9000 RCLONE_S3_REGION=us-east-1
./transfer.sh copy samples/concurrency-test :s3:testpress-backup/fresh-clone-test
rclone check samples/concurrency-test :s3:testpress-backup/fresh-clone-test --config /dev/null
```

Prerequisites: Git, Bash, Python 3, Rclone, Docker with Compose, and a running MinIO server. Create the destination bucket if it does not exist. This test reused an existing MinIO server; independent MinIO startup remains unverified.

## Final Mandatory and Bonus Experiments

### PDF requirement
```bash
mkdir -p samples/source/documents
printf "Rclone PDF transfer test\nTestpress DevOps exercise\n" > /tmp/rclone-pdf.txt
cupsfilter -m application/pdf /tmp/rclone-pdf.txt > samples/source/documents/sample.pdf
file samples/source/documents/sample.pdf
rclone copyto samples/source/documents/sample.pdf :s3:testpress-source/documents/sample.pdf --config /dev/null --progress
rclone check samples/source/documents :s3:testpress-source/documents --config /dev/null
```

### Explicit S3 object listing
```bash
rclone ls :s3:testpress-source --config /dev/null
```

### Invalid credential test
```bash
RCLONE_S3_PROVIDER=Minio RCLONE_S3_ACCESS_KEY_ID="wrong-user" RCLONE_S3_SECRET_ACCESS_KEY="wrong-password" RCLONE_S3_ENDPOINT=http://127.0.0.1:9000 RCLONE_S3_REGION=us-east-1 rclone lsd :s3: --config /dev/null --retries 1 --low-level-retries 1
```

### Fresh-volume MinIO validation
```bash
docker compose down -v
docker compose up -d
curl -i http://localhost:9000/minio/health/ready
docker compose ps -a
```

The Compose setup uses `minio-init` to set `/data` ownership before the non-root MinIO service starts.

### Two S3 endpoints
Primary MinIO uses port `9000`; a second MinIO instance was started on `9100`.

Temporary remotes were supplied entirely through `RCLONE_CONFIG_FIRST_*` and `RCLONE_CONFIG_SECOND_*` environment variables, then copied with:
```bash
rclone copy first:testpress-source/bonus-test second:testpress-target/bonus-test --config /dev/null --progress
rclone check first:testpress-source/bonus-test second:testpress-target/bonus-test --config /dev/null
```

### Checker performance
```bash
time rclone copy samples/bonus-test :s3:testpress-source/bonus-test --config /dev/null --checkers 1 --transfers 1
time rclone copy samples/bonus-test :s3:testpress-source/bonus-test --config /dev/null --checkers 8 --transfers 1
```

### Multi-thread stream comparison
```bash
mkfile 512m samples/bonus-test/large-multithread.bin
rclone copyto samples/bonus-test/large-multithread.bin :s3:testpress-source/large-mt-1.bin --config /dev/null --multi-thread-streams 1 --progress
rclone copyto samples/bonus-test/large-multithread.bin :s3:testpress-source/large-mt-4.bin --config /dev/null --multi-thread-streams 4 --progress
```

### Multipart upload investigation
```bash
rclone copyto samples/bonus-test/large-multithread.bin :s3:testpress-source/multipart-test.bin --config /dev/null --bwlimit 5M --progress
# Interrupt with Ctrl+C
rclone backend list-multipart-uploads :s3:testpress-source --config /dev/null
rclone backend cleanup :s3:testpress-source --config /dev/null
rclone backend list-multipart-uploads :s3:testpress-source --config /dev/null
```

`--s3-leave-parts-on-error` can be used when intentionally investigating leftover multipart parts.

### Crypt backend
```bash
export RCLONE_CONFIG_CRYPT_TYPE=crypt
export RCLONE_CONFIG_CRYPT_REMOTE=:s3:testpress-source/crypt-data
export RCLONE_CONFIG_CRYPT_PASSWORD="$(rclone obscure testpass123)"
export RCLONE_CONFIG_CRYPT_PASSWORD2="$(rclone obscure salt123)"
echo "Encrypted Rclone test" > samples/crypt-test.txt
rclone copyto samples/crypt-test.txt crypt:secret.txt --config /dev/null
rclone ls crypt: --config /dev/null
rclone ls :s3:testpress-source/crypt-data --config /dev/null
```

### Scheduled transfer example
```bash
cat cron-example.txt
```

The example runs the transfer every hour and redirects stdout/stderr to `scheduled.log`.

### Python subprocess
```bash
python3 run_rclone.py
rclone check samples/bonus-test :s3:testpress-backup/python-test --config /dev/null
```

### Mount investigation
```bash
rclone mount --help | head
```
`rclone mount` requires a FUSE implementation on macOS. macFUSE was not installed, so this optional bonus was investigated but intentionally skipped.
