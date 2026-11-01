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
