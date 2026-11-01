# Rclone Experiment Results

## Environment
- Platform: macOS
- Rclone: v1.73.0
- Storage: Local filesystem

## 1. File Listing
- Created nested documents, backups, and videos directories.
- Created a 100 MiB test file (104857600 bytes).
- rclone ls successfully listed files and their sizes.

## 2. Copy Experiments
| Experiment | Observed result |
|---|---|
| Initial copy | 3 files transferred, 100 MiB total |
| Repeated copy | 0 B transferred; 3 files checked |
| Added new-file.txt | 1 file transferred, 27 B |
| Modified readme.txt | 1 file transferred, 35 B |
| Destination-only old-backup.txt | Preserved by rclone copy; 0 B transferred |

Conclusion: rclone copy transfers new or changed files without deleting destination-only files.

## 3. Move Experiment
- Moved move-test.txt from move-source to move-destination.
- Output: Renamed: 1; Server Side Moves: 1 @ 37 B.
- Verified that the file exists only in move-destination.

## 4. Sync Safety Experiment
- Dry run identified old-backup.txt for deletion (16 B).
- Dry run skipped the actual deletion.
- Actual sync deleted 1 file and freed 16 B.
- No file data needed transferring.

Conclusion: rclone sync makes the destination match the source and may delete destination-only files. Always inspect --dry-run first.

## 5. Integrity Verification
- Command: rclone check samples/source samples/destination
- Result: 0 differences found.
- Result: 4 matching files.

## 6. Delete Experiment
- Created a temporary 15 B file.
- rclone delete removed 1 file and freed 15 B.
- Verified that the directory remained empty after deletion.

## Key Learnings
- copy: transfer new or changed files; preserve destination-only files.
- move: transfer files and remove successfully moved source files.
- sync: make destination match source, including deletions.
- check: compare source and destination without modifying files.
- delete: remove files from the specified location.
- --dry-run: preview operations without changing data.

## Next Phase
Set up locally hosted S3-compatible storage using MinIO and Docker Compose.

## Phase 4 - MinIO Docker Compose Results

### Objective
Run a local S3-compatible MinIO server using Docker Compose without using a paid cloud service.

### Results
- Docker Compose configuration validation passed.
- Initial MinIO image downloads from Docker Hub and Quay.io failed due to registry access or unavailable image references.
- Successfully downloaded the Alpine Community MinIO image: alpine/minio:latest-release.
- Pinned the image in docker-compose.yml using its SHA-256 digest.
- Created the rclone-minio container and the persistent rclone-playground_minio-data volume.
- The Alpine MinIO container initially failed because the existing volume directories were owned by root.
- Resolved the permission issue by changing volume ownership to the minio user.
- Restarted MinIO successfully.
- Verified the MinIO readiness endpoint returned HTTP/1.1 200 OK.

### Endpoints
- S3 API: http://localhost:9000
- MinIO Console: http://localhost:9001

### Key Learning
Docker images define the application environment, containers run the application, and named volumes preserve data across container recreation. File permissions still apply inside containers.

### Reproducibility
The Alpine MinIO image was successfully downloaded on ARM64. The pinned image digest still requires verification on other architectures, such as AMD64.
