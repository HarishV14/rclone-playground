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

## Phase 5 - S3 Operations and Config-Free Access Results

### Configuration
- Used MinIO at http://127.0.0.1:9000 with credentials supplied through environment variables.
- Used the direct :s3: backend with --config /dev/null, without relying on rclone.conf.
- Created testpress-source and testpress-backup buckets.

### Upload and download
- Uploaded four objects totaling 100 MiB to testpress-source in approximately 1.3 seconds.
- Verified the upload: 0 differences found; 4 matching files.
- Downloaded four objects totaling 100 MiB to samples/s3-download in approximately 0.8 seconds.
- Verified the downloaded files against the original source: 0 differences found; 4 matching files.

### Server-side copy
- Copied four objects (100 MiB) from testpress-source to testpress-backup in approximately 0.5 seconds.
- Rclone reported: Server Side Copies: 4 @ 100.000 MiB.
- Verified both buckets: 0 differences found; 4 matching files.

### Object deletion
- Uploaded a temporary delete-test.txt object using rclone rcat.
- Deleted only that object using rclone deletefile.
- Final bucket comparison: 0 differences found; 4 matching files.

### Key learning
Config-free Rclone can connect to S3-compatible storage through runtime environment variables. Server-side copying lets the storage service copy objects internally without transferring the object contents through the local machine.

## Phase 6 - Large Transfers and Reliability Results

### Large-file upload
- Created a 1 GiB file using mkfile.
- Uploaded 1 GiB with --bwlimit 10M in 1m 45.9s at approximately 9.992 MiB/s.
- Repeated the upload: 0 B transferred in 0.0s.
- Configured --transfers 2, --checkers 4, --retries 3, and --low-level-retries 5; no retryable failure was intentionally induced.

### Interrupted upload and recovery
- Interrupted the 1 GiB upload at 13% (135.531 MiB) using Ctrl+C.
- The incomplete object was not visible in a normal S3 object listing.
- Restarted the upload, transferring the full 1 GiB in 1m 45.4s.
- Original and recovered objects had matching MD5 hashes: cd573cfaace07e7949bc0c46028904ff.
- Recovery was a full retransmission, not a demonstrated partial resume.

### Concurrency comparison
| Test | Data | Elapsed time |
|---|---|---|
| --transfers 1, --bwlimit 5M | 80 MiB | 15.9s |
| --transfers 4, --bwlimit 5M | 80 MiB | 15.9s |
| --transfers 4, no bandwidth limit | 80 MiB | 0.7s |

- The shared bandwidth limit was the bottleneck in both limited tests.
- Removing the bandwidth limit greatly improved throughput on local MinIO.
- These results do not isolate the performance benefit of concurrency without bandwidth limits.
- Final integrity check: 0 differences found; 4 matching files.

### Key learning
Rclone skips unchanged objects, supports configurable concurrency and bandwidth limits, and can recover from interrupted uploads by retransferring data. A successful restart does not necessarily mean an interrupted multipart upload was resumed.

## Phase 7 - Reusable Transfer Script Results

- Copy: 4 files, 80 MiB, completed in 0.8 seconds.
- Invalid source: exit code 3 propagated correctly.
- Dry-run sync: planned deletion of a 37-byte destination-only file; file remained present.
- Real sync --execute: deleted the extra 37-byte file.
- Integrity verification: 0 differences, 4 matching files.
- Missing S3 variables: helpful error and exit code 2.
- Local-to-local transfer without S3 variables: 4 files, 80 MiB, successful.
- Explicit S3 flags with --config /dev/null: listed testpress-source and testpress-backup.
- Incorrect endpoint port 9999: connection refused; port 9000 restored successfully.
- Remaining: fresh-clone reproducibility test and portable sample generation.
