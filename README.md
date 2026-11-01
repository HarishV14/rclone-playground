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
├── docker-compose.yml   # MinIO setup
├── transfer.sh          # Reusable transfer script (upcoming)
├── .env.example         # Example MinIO environment variables
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

## Phase 4 - Local S3 Storage with MinIO

This project runs an S3-compatible object storage server locally using Docker Compose. No paid cloud account is required.

### Prerequisites
- Docker and Docker Compose
- Rclone

### Setup

1. Clone this repository and enter the project directory.
2. Create your local environment file:

```bash
cp .env.example .env
```

3. Replace the example password in `.env` with a strong password. Never commit `.env`.
4. Start MinIO:

```bash
docker compose up -d
```

5. Verify the service:

```bash
docker compose ps
curl -i http://localhost:9000/minio/health/ready
```

A healthy MinIO server returns HTTP/1.1 200 OK.

### Local Endpoints
- S3 API: http://localhost:9000
- Web console: http://localhost:9001

Use the credentials configured in `.env` to sign in to the console.

### Storage and Security
- MinIO data persists in the Docker-managed `minio-data` volume.
- Both ports are bound to 127.0.0.1, limiting access to the local machine.
- `.env` is excluded from Git; `.env.example` contains placeholder credentials only.
- The Docker image is pinned by SHA-256 digest for version consistency.

### Reproducibility Note
The image was downloaded and tested on ARM64. AMD64 compatibility with the pinned digest has not yet been verified.

## Phase 5 - S3 Operations and Config-Free Access (Completed)
- Connected Rclone to local MinIO using environment variables and the :s3: backend.
- Disabled persistent Rclone configuration using --config /dev/null.
- Created testpress-source and testpress-backup buckets.
- Uploaded four objects totaling 100 MiB and verified their integrity.
- Downloaded the objects and verified the restored files.
- Copied objects between S3 buckets using server-side copying.
- Created and deleted a temporary S3 object without affecting the backup.
- Confirmed 0 differences and 4 matching objects after deletion.

See [commands.md](commands.md) and [results.md](results.md) for commands and observations.

## Upcoming Work
- Phase 6: Large transfers, retries, interruption recovery, performance tuning, and config-free flag-based access.
- Phase 7: Reusable Bash transfer script, sync safety, and final documentation.

## Security
Local sample data, credentials, environment files, and Rclone configuration files are excluded from Git using .gitignore. Real credentials must never be committed.
