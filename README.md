# Rclone Playground

Hands-on DevOps exercise demonstrating file transfers, synchronization, verification, and S3-compatible object storage using Rclone.

## Technology Stack
- Rclone v1.73.0
- Docker and Docker Compose
- MinIO (local S3-compatible object storage)
- Bash scripting
- macOS development environment

## Project Structure
```text
rclone-playground/
├── README.md            # Project overview
├── commands.md          # Commands and examples
├── results.md           # Experiment observations
├── docker-compose.yml   # MinIO setup (upcoming)
├── transfer.sh          # Reusable transfer script (upcoming)
└── .gitignore           # Excluded local files and credentials
```

## Phase 1 - Fundamentals
Understood local file storage, S3 object storage, and the purpose of Rclone.

## Phase 2 - Environment Setup
Installed and verified Git, Docker, Docker Compose, and Rclone. Initialized and pushed the GitHub repository.

## Phase 3 - Local File Operations (Completed)
- Listed nested files with rclone ls.
- Tested initial, repeated, new-file, and modified-file copies.
- Confirmed that copy preserves destination-only files.
- Moved files and verified source removal.
- Previewed synchronization with --dry-run.
- Confirmed that sync removes destination-only files.
- Verified file integrity using rclone check.
- Deleted temporary files using rclone delete.

See [commands.md](commands.md) and [results.md](results.md) for commands and observations.

## Upcoming Work
- Phase 4: Run MinIO with Docker Compose.
- Phase 5: S3 bucket operations and transfers.
- Phase 6: Config-free S3 access using flags and environment variables.
- Phase 7: Large transfers, retries, interruption recovery, and performance tuning.
- Phase 8: Reusable Bash transfer script and final documentation.

## Security
Local sample data, credentials, environment files, and Rclone configuration files are excluded from Git using .gitignore. Real credentials must never be committed.
