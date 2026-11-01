# Rclone File Transfer and Storage Automation

## Objective

The objective of this exercise was to learn how to use Rclone to transfer, synchronize, verify, and manage files across local storage and S3-compatible object storage without depending on manually maintained `rclone.conf` files.

The exercise focused on reliable file transfer, large-file handling, synchronization safety, configuration-free S3 access, automation, security, and reproducibility.

---

## Environment

The experiments were performed using:

* macOS
* Rclone v1.73.0
* Docker Desktop
* Docker Compose
* MinIO as the local S3-compatible storage service
* Bash
* Python 3
* Git and GitHub

No paid cloud storage provider was used.


---

# 1. Environment Setup

Rclone, Docker, Docker Compose, and Git were verified before starting the experiments.

Two local directories were used to simulate different storage locations.

```bash
samples/source
samples/destination
```

The sample data included:

* Nested directories
* Text files
* A PDF file
* A 100 MiB binary test file
* A 1 GiB large-file test

Example:

```text
samples/source/
├── backups/
│   └── backup.txt
├── documents/
│   ├── readme.txt
│   ├── new-file.txt
│   └── sample.pdf
└── videos/
    ├── test-video.bin
    └── large-test.bin
```

A real PDF was generated and verified using:

```bash
file samples/source/documents/sample.pdf
```

Result:

```text
PDF document, version 1.3, 1 pages
```


---

# 2. Basic File Operations

## Listing Files

```bash
rclone ls samples/source
```

This recursively listed the files and their sizes without modifying any data.


---

## Copy

```bash
rclone copy samples/source samples/destination --progress
```

The first execution copied all files.

Running the same command again resulted in:

```text
Transferred: 0 B / 0 B
```

This demonstrated that Rclone skips unchanged files.

A destination-only file was also created and the copy command was repeated.

The destination-only file remained untouched.

### Copy behavior

`rclone copy`:

* Copies new files.
* Updates changed files.
* Skips unchanged files.
* Does not delete destination-only files.


---

## Move

```bash
rclone move samples/move-source samples/move-destination --progress
```

The file was transferred to the destination and removed from the source.

### Move behavior

`rclone move` performs a copy-like operation but removes successfully transferred source files.


---

## Sync

Before executing synchronization, a dry run was performed:

```bash
rclone sync samples/source samples/destination --dry-run
```

Rclone detected a destination-only file and reported that it would be deleted.

The actual synchronization was then executed:

```bash
rclone sync samples/source samples/destination --progress
```

The destination-only file was removed.

### Sync behavior

`rclone sync` makes the destination match the source.

This means destination-only files can be deleted.

For this reason, `--dry-run` should be used before executing potentially destructive synchronization operations.


---

## Delete

```bash
rclone delete samples/delete-test --progress
```

The files inside the directory were deleted while the directory itself remained.

For deleting one exact file or S3 object, `deletefile` was also tested.


---

## Integrity Verification

```bash
rclone check samples/source samples/destination
```

Observed result:

```text
0 differences found
4 matching files
```

This verified that the source and destination contained identical file data.


---

# 3. Local S3-Compatible Storage using MinIO

MinIO was hosted locally using Docker Compose.

The MinIO endpoints were:

```text
S3 API:     http://localhost:9000
Web Console: http://localhost:9001
```

Credentials were supplied through environment variables loaded from `.env`.

The real `.env` file is excluded from Git.

An `.env.example` file is provided for reproducibility.

The MinIO readiness endpoint was verified using:

```bash
curl -i http://localhost:9000/minio/health/ready
```

Successful response:

```text
HTTP/1.1 200 OK
```


---

# 4. Docker Volume Reproducibility

The Alpine MinIO image runs using the non-root `minio` user.

A fresh Docker volume is initially owned by root, which caused MinIO to fail with:

```text
Unable to write to the backend
```

To make the setup reproducible, a `minio-init` service was added to `docker-compose.yml`.

It runs before MinIO and changes the volume ownership to the `minio` user.

The final startup sequence is:

```text
Fresh Docker Volume
        ↓
minio-init
        ↓
chown /data
        ↓
MinIO starts
```

Fresh-volume testing produced:

```text
minio-init → Exited (0)
MinIO      → Up
MinIO fresh-volume startup: HEALTHY
```

This removed the need for developers to manually fix volume ownership.


---

# 5. S3-Compatible Storage Operations

Two buckets were created:

```text
testpress-source
testpress-backup
```

Bucket creation:

```bash
rclone mkdir :s3:testpress-source --config /dev/null
rclone mkdir :s3:testpress-backup --config /dev/null
```

Bucket listing:

```bash
rclone lsd :s3: --config /dev/null
```


---

## Upload to S3

```bash
rclone copy samples/source :s3:testpress-source \
  --config /dev/null \
  --progress
```

Observed result:

```text
Transferred: 100 MiB
Transferred: 4 / 4
```


---

## Download from S3

```bash
rclone copy :s3:testpress-source samples/s3-download \
  --config /dev/null \
  --progress
```

The downloaded data was verified against the original source:

```text
0 differences found
4 matching files
```


---

## Listing S3 Objects

```bash
rclone ls :s3:testpress-source --config /dev/null
```

This displayed objects such as:

```text
documents/sample.pdf
documents/readme.txt
videos/test-video.bin
videos/large-test.bin
```


---

## Bucket-to-Bucket Copy

```bash
rclone copy :s3:testpress-source :s3:testpress-backup \
  --config /dev/null \
  --progress
```

Rclone reported:

```text
Server Side Copies: 4
```

This demonstrated server-side copying between buckets hosted on the same MinIO server.


---

## S3 Object Deletion

A temporary object was created and deleted using:

```bash
rclone deletefile :s3:testpress-backup/delete-test.txt \
  --config /dev/null
```

The original backup objects remained intact.


---

# 6. Configuration-Free Rclone

This was a mandatory part of the exercise.

All S3 operations were performed without relying on a persistent `rclone.conf`.

The configuration file was explicitly disabled using:

```bash
--config /dev/null
```

Three config-free approaches were explored.


---

## Direct `:s3:` Backend

Example:

```bash
rclone lsd :s3: --config /dev/null
```


---

## Environment Variables

Example:

```bash
export RCLONE_S3_PROVIDER=Minio
export RCLONE_S3_ACCESS_KEY_ID="$MINIO_ROOT_USER"
export RCLONE_S3_SECRET_ACCESS_KEY="$MINIO_ROOT_PASSWORD"
export RCLONE_S3_ENDPOINT=http://127.0.0.1:9000
export RCLONE_S3_REGION=us-east-1
```

Rclone then used these values at runtime.


---

## Explicit Command-Line Flags

Rclone was also executed with:

```bash
--s3-provider Minio
--s3-access-key-id ...
--s3-secret-access-key ...
--s3-endpoint http://127.0.0.1:9000
--s3-region us-east-1
```

No Rclone configuration file was required.


---

## Invalid Credentials

A wrong access key and password were deliberately supplied.

MinIO returned:

```text
403 InvalidAccessKeyId
```

This confirmed that Rclone was using the runtime credentials rather than hidden saved configuration.


---

## Invalid Endpoint

The endpoint was deliberately changed from:

```text
127.0.0.1:9000
```

to:

```text
127.0.0.1:9999
```

Rclone returned:

```text
connect: connection refused
```

Restoring port `9000` restored connectivity.


---

## Recommended Production Approach

For production use, I would use:

* Short-lived or scoped credentials.
* Environment variables populated by a secret manager.
* HTTPS endpoints.
* `:s3:` or temporary runtime remotes.
* `--config /dev/null`.
* No credentials committed into Git.
* No manually maintained Rclone configuration file inside application workers.

For systems such as Celery workers, credentials can be injected at runtime and Rclone invoked through `subprocess`.


---

# 7. Large Transfer Reliability

A 1 GiB test file was created.

```bash
mkfile 1g samples/source/videos/large-test.bin
```

Upload command:

```bash
rclone copyto samples/source/videos/large-test.bin \
  :s3:testpress-source/videos/large-test.bin \
  --config /dev/null \
  --transfers 2 \
  --checkers 4 \
  --bwlimit 10M \
  --progress \
  --stats 5s \
  --retries 3 \
  --low-level-retries 5
```

Observed result:

```text
Transferred: 1 GiB / 1 GiB
Speed: 9.992 MiB/s
Elapsed time: 1m45.9s
```

The approximately 10 MiB/s result confirmed that `--bwlimit 10M` was working.


---

## Repeated Upload

The exact command was executed again.

Result:

```text
Transferred: 0 B / 0 B
Elapsed time: 0.0s
```

Rclone detected that the destination file was already unchanged and skipped it.


---

# 8. Interrupted Transfer

A 1 GiB upload was limited to 5 MiB/s and interrupted manually at approximately 13%.

Observed before interruption:

```text
Transferred: 135.531 MiB / 1 GiB
13%
```

The incomplete object was not visible as a completed S3 object.

The command was restarted.

Rclone transferred the complete 1 GiB again.

Observed result:

```text
Transferred: 1 GiB / 1 GiB
Elapsed time: 1m45.4s
```

The original file and recovered object were verified using MD5:

```text
cd573cfaace07e7949bc0c46028904ff
cd573cfaace07e7949bc0c46028904ff
```

Therefore, the recovered object was identical.

The experiment demonstrated that restarting the operation caused retransmission rather than resuming from the previous 13%.


---

# 9. Concurrency and Bandwidth

Four 20 MiB files were used for concurrency testing.

### One transfer

```text
--transfers 1
--bwlimit 5M

Elapsed: 15.9s
```

### Four transfers

```text
--transfers 4
--bwlimit 5M

Elapsed: 15.9s
```

The shared bandwidth limit remained the bottleneck.

### Four transfers without bandwidth limit

```text
--transfers 4

Elapsed: 0.7s
```

This demonstrated that increasing transfer concurrency does not automatically improve throughput when bandwidth is already limited.


---

# 10. `--checkers` Experiment

The same remote data was checked using different checker concurrency.

Results:

```text
--checkers 1 → 0.383s
--checkers 8 → 0.366s
```

The difference was small because the dataset contained only a few files and MinIO was hosted locally.


---

# 11. Multi-Thread Stream Experiment

A 512 MiB file was uploaded.

Results:

```text
--multi-thread-streams 1 → 8.4s
--multi-thread-streams 4 → 7.2s
```

Four streams improved transfer speed in this local experiment.


---

# 12. Multipart Upload Investigation

A large upload was deliberately interrupted.

Pending multipart uploads were inspected using:

```bash
rclone backend list-multipart-uploads \
  :s3:testpress-source \
  --config /dev/null
```

After a normal interruption, the result was:

```json
{
    "testpress-source": []
}
```

This showed that Rclone cleaned up the incomplete multipart upload.

Multipart cleanup was also demonstrated using:

```bash
rclone backend cleanup :s3:testpress-source \
  --config /dev/null
```


---

# 13. Synchronization and Data Safety

A destination-only file named `keep-test.txt` was created.

The reusable script was executed in sync mode:

```bash
./transfer.sh sync \
  samples/concurrency-test \
  :s3:testpress-backup/script-test
```

The script automatically used `--dry-run`.

Rclone reported:

```text
Deleted: 1
```

but verification confirmed that the file still existed.

The real synchronization was then explicitly executed:

```bash
./transfer.sh sync \
  samples/concurrency-test \
  :s3:testpress-backup/script-test \
  --execute
```

The extra file was deleted.

Final verification:

```text
0 differences found
4 matching files
```

This demonstrated why `rclone sync` is potentially dangerous and why destructive operations should first be inspected using `--dry-run`.


---

# 14. Reusable Bash Automation

A reusable Bash script named `transfer.sh` was implemented.

Example:

```bash
./transfer.sh copy SOURCE DESTINATION
```

Safe synchronization:

```bash
./transfer.sh sync SOURCE DESTINATION
```

Real synchronization:

```bash
./transfer.sh sync SOURCE DESTINATION --execute
```

The script provides:

* `copy`
* `sync`
* Argument validation
* Rclone dependency validation
* Config-free S3 support
* Progress reporting
* Log file generation
* Safe sync behavior
* Error propagation
* Exit-code handling

An invalid source was tested.

Result:

```text
Transfer failed with exit code: 3
Script exit code: 3
```

Missing S3 environment variables were also tested.

Result:

```text
Error: Missing S3 environment variable
Exit code: 2
```

Local-to-local transfers still worked without S3 credentials.


---

# 15. Two Different S3 Endpoints

A second MinIO instance was started on:

```text
http://127.0.0.1:9100
```

The first instance remained on:

```text
http://127.0.0.1:9000
```

Data was copied between both endpoints using temporary environment-defined Rclone remotes.

Result:

```text
Transferred: 40 MiB
Transferred: 4 / 4
Elapsed time: 0.8s
```

Verification:

```text
0 differences found
4 matching files
```

Unlike same-endpoint bucket copies, no `Server Side Copies` result appeared.

Therefore:

```text
Same S3 server:
Bucket A → server-side copy → Bucket B

Different S3 servers:
S3 A → Rclone process → S3 B
```


---

# 16. Rclone Crypt Backend

The Rclone `crypt` backend was tested on top of MinIO.

Through the encrypted Rclone view:

```text
secret.txt
```

Through the underlying raw S3 storage:

```text
gkkgco6roe6slqeof73ahjv6ko
```

The logical plaintext filename was therefore not visible directly in the S3 backend.

This demonstrated how Rclone's `crypt` backend can encrypt file data and obfuscate filenames before storing them remotely.


---

# 17. Scheduled Transfer

A cron example was created:

```text
0 * * * * cd /Users/harishv/workspace/rclone-playground && ./transfer.sh copy samples/bonus-test :s3:testpress-backup/scheduled >> scheduled.log 2>&1
```

This would execute the copy operation once every hour.

The cron example was documented but was not installed into the actual user crontab.


---

# 18. Python Integration

Rclone automation was invoked from Python using `subprocess.run`.

Flow:

```text
Python
  ↓
subprocess.run
  ↓
transfer.sh
  ↓
Rclone
  ↓
MinIO
```

The resulting S3 files were verified.

Result:

```text
0 differences found
5 matching files
```

This demonstrated how an application or Celery worker could invoke Rclone programmatically.


---

# 19. Security

The following security practices were followed:

* Credentials were not hardcoded into `transfer.sh`.
* `.env` is excluded using `.gitignore`.
* `rclone.conf` was not required.
* `--config /dev/null` was used for config-free demonstrations.
* Real credentials were not committed to GitHub.
* MinIO ports were bound to `127.0.0.1`.
* Dry-run was used before destructive synchronization.
* Production credentials should come from a secret manager.
* Command-line credential flags were used for demonstration only because they can be visible in process listings.


---

# 21. Reproducibility

The project was cloned into a separate directory to simulate another developer using the repository.

The following were verified:

* Repository clone successful.
* `transfer.sh` retained executable permissions.
* `.env` remained ignored.
* Portable sample files were generated.
* Transfer from the fresh clone succeeded.
* Integrity verification reported 0 differences.
* MinIO was started successfully using a completely fresh Docker volume.
* The `minio-init` service fixed volume permissions automatically.

The project can therefore be reproduced using the repository instructions without manually creating an Rclone configuration file.


---

# Key Learnings

The main learnings from this exercise were:

* Rclone can transfer files between local storage and S3-compatible object storage.
* `copy`, `move`, and `sync` have significantly different deletion behavior.
* Repeated copy operations skip unchanged files.
* `sync` can delete destination-only data and must be used carefully.
* `--dry-run` is important before destructive operations.
* `rclone check` verifies transfer integrity.
* Rclone can operate without `rclone.conf`.
* Runtime environment variables are appropriate for automated environments.
* Large S3 transfers use multipart upload mechanisms.
* Restarting an interrupted upload does not necessarily mean resuming previous progress.
* Server-side copying avoids unnecessary network transfers when supported.
* Different S3 endpoints generally require data to pass through the Rclone client.
* Concurrency and bandwidth settings affect transfer performance differently.
* Rclone can be automated through Bash, cron-style scheduling, and Python applications.
* Rclone's `crypt` backend can encrypt file contents and filenames before remote storage.


---

# Deliverables

The repository contains the required deliverables:


1. `README.md` — setup and reproduction instructions.
2. `transfer.sh` — reusable transfer automation script.
3. `commands.md` — commands used during experiments.
4. `results.md` — experiment results and observations.
5. `docker-compose.yml` — local MinIO S3-compatible storage setup.

Additional bonus artifacts include:

* `.env.example`
* `cron-example.txt`
* `run_rclone.py`


---

# Final Status

All mandatory requirements were completed and verified.

The major bonus challenges were also completed, including:

* Two separate S3 endpoints
* Server-side copy investigation
* `--transfers`
* `--checkers`
* `--multi-thread-streams`
* Multipart upload investigation
* Crypt backend
* Scheduled-transfer example
* Python `subprocess`
