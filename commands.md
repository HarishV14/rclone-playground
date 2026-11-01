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
