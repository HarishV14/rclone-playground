import subprocess

result = subprocess.run(
    [
        "./transfer.sh",
        "copy",
        "samples/bonus-test",
        ":s3:testpress-backup/python-test",
    ],
    text=True,
    capture_output=True,
)

print(result.stdout)
print(result.stderr)
print("Exit code:", result.returncode)
