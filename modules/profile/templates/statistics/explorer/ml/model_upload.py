#!/usr/bin/env python3
# SPDX-License-Identifier: Apache-2.0
"""
S3 Model Upload Script

Uploads model files or directories to S3/Swift storage via boto3.
This script will attempt to create a bucket and will version
the model using a timestamp following YYYYMMDDHHMMSS format.

The full S3 path will look like:
s3://bucket/class/language/timestamp/filename

For directories, the structure is preserved under the timestamp folder.
"""

import argparse
import configparser
import hashlib
import os
import shutil
import sys
from datetime import datetime
from pathlib import Path

import boto3
import urllib3
from botocore.config import Config
from botocore.exceptions import ClientError

# Boto config with Swift-compatible settings
BOTO_CONFIG = {
    "signature_version": "v4",
    "retries": {"max_attempts": 3},
    "s3": {
        "addressing_style": "path",
        "chunked_encoding": False,
    },
    "tcp_keepalive": False,
}
CA_BUNDLE_PATH = "/etc/ssl/certs/wmf-ca-certificates.crt"
PUBLISHED_MODELS_DIR = "/srv/published/wmf-ml-models"
PUBLISHED_MODELS_URL = "https://analytics.wikimedia.org/published/wmf-ml-models"


class S3ModelUploader:
    def __init__(self, config_file: str):
        self.config_file = config_file
        self.s3_client = None
        self._load_config()

    def _load_config(self):
        """Load S3 configuration from s3cmd config file format."""
        if not os.path.exists(self.config_file):
            raise FileNotFoundError(f"Config file not found: {self.config_file}")
        print(f"Loading configuration from: {self.config_file}")
        # Parse s3cmd config file
        config = configparser.ConfigParser()
        config.read(self.config_file)
        # Read the values from default section
        section = "default"
        access_key = config.get(section, "access_key")
        secret_key = config.get(section, "secret_key")
        host_base = config.get(section, "host_base")
        # Configure boto3 client for Swift/S3-compatible service
        self.s3_client = boto3.client(
            "s3",
            aws_access_key_id=access_key,
            aws_secret_access_key=secret_key,
            endpoint_url=host_base,
            region_name="us-east-1",  # Required for boto3, but ignored by Swift
            verify=CA_BUNDLE_PATH,  # Verify SSL with local certificates
            config=Config(**BOTO_CONFIG),
        )
        # Disable warnings connected to lack of SSL verification
        urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)

    def _ensure_bucket_exists(self, bucket_name: str) -> None:
        """Ensure the S3 bucket exists, create if it doesn't."""
        try:
            self.s3_client.head_bucket(Bucket=bucket_name)
            print(f"Bucket {bucket_name} already exists, skipping creation")
        except ClientError as e:
            error_code = e.response["Error"]["Code"]
            if error_code == "404" or error_code == "NoSuchBucket":
                print(f"Creating bucket: {bucket_name}")
                self.s3_client.create_bucket(Bucket=bucket_name)
            elif error_code == "403" or error_code == "Forbidden":
                raise RuntimeError(f"Access denied when checking bucket {bucket_name}")
            else:
                raise RuntimeError(f"Could not access bucket {bucket_name}: {e}")
        except Exception as e:
            raise RuntimeError(f"Unexpected error accessing bucket {bucket_name}: {e}")

    def _upload_file(self, local_path: str, s3_key: str, bucket: str) -> None:
        """Upload a single file to S3."""
        file_size = os.path.getsize(local_path)
        print(f"UPLOADING {local_path} ({file_size} bytes) to s3://{bucket}/{s3_key}")
        try:
            self.s3_client.upload_file(local_path, bucket, s3_key)
            print(f"Successfully uploaded: {s3_key}")
        except Exception as e:
            raise RuntimeError(f"Failed to upload {local_path}: {e}")

    def _get_files_to_upload(self, path: str) -> list[tuple[str, str]]:
        """Get list of files to upload with their relative paths."""
        if os.path.isfile(path):
            return [(path, os.path.basename(path))]
        elif os.path.isdir(path):
            files = []
            base_path = Path(path)
            for file_path in base_path.rglob("*"):
                if file_path.is_file():
                    files.append(
                        (str(file_path), str(file_path.relative_to(base_path)))
                    )
            return files
        else:
            raise ValueError(f"Path does not exist: {path}")

    def upload(
        self,
        model_path: str,
        model_type: str,
        model_lang: str,
        bucket: str,
        timestamp: str,
    ) -> bool:
        """Upload model file(s) to S3. Returns `True` on success."""
        self._ensure_bucket_exists(bucket)
        files_to_upload = self._get_files_to_upload(model_path)

        if not files_to_upload:
            print("No files found to upload")
            sys.exit(1)

        print(f"Found {len(files_to_upload)} file(s) to upload")
        model_prefix = f"{model_type}/{model_lang}/{timestamp}"

        for local_file, relative_path in files_to_upload:
            s3_key = f"{model_prefix}/{relative_path}"
            self._upload_file(local_file, s3_key, bucket)

        print(f"Successfully uploaded {len(files_to_upload)} files")
        return True

    def _calculate_sha512(self, file_path: str) -> str:
        """Calculate SHA512 checksum of a file."""
        sha512_hash = hashlib.sha512()
        with open(file_path, "rb") as f:
            for chunk in iter(lambda: f.read(4096), b""):
                sha512_hash.update(chunk)
        return sha512_hash.hexdigest()

    def publish_locally(
        self, model_path: str, model_type: str, model_lang: str, timestamp: str
    ) -> bool:
        """Copy files to local published directory and generate checksums."""
        target_dir = f"{PUBLISHED_MODELS_DIR}/{model_type}/{model_lang}/{timestamp}"
        print(f"Creating directory: {target_dir}")
        os.makedirs(target_dir, exist_ok=True)
        files_to_copy = self._get_files_to_upload(model_path)
        for local_file, relative_path in files_to_copy:
            target_file = os.path.join(target_dir, relative_path)
            target_file_dir = os.path.dirname(target_file)

            # Create subdirectories if needed
            if target_file_dir != target_dir:
                os.makedirs(target_file_dir, exist_ok=True)

            print(f"Copying {local_file} to {target_file}")
            shutil.copy2(local_file, target_file)

            # Generate SHA512 checksum
            print(f"Generating SHA512 checksum for {relative_path}")
            checksum = self._calculate_sha512(local_file)
            checksum_file = f"{target_file}.sha512"

            with open(checksum_file, "w") as f:
                f.write(f"{checksum}  {os.path.basename(target_file)}\n")

        print("Local publishing completed successfully!")
        print("Please note that it may take up to 30 mins to see the new files")
        print(f"in {PUBLISHED_MODELS_URL}")
        return True


def main():
    """Upload model files or directories to S3/Swift storage.

    This script uploads model files to S3 with automatic versioning using timestamps.
    The full S3 path will be: s3://bucket/model-type/model-lang/timestamp/filename

    For directories, the internal structure is preserved under the timestamp folder.

    Examples:
        # Upload a single model file
        model-upload model.bin goodfaith enwiki

        # Upload a model directory to custom bucket
        model-upload /path/to/model/dir damaging frwiki --bucket custom-bucket

        # Use custom config file and skip publishing
        model-upload model.bin goodfaith enwiki --config-file /custom/config.cfg --no-publish
    """
    parser = argparse.ArgumentParser(
        description=(
            "Upload model files or directories to "
            "S3/Swift storage with automatic versioning."
        ),
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""Examples:
  %(prog)s model.bin goodfaith enwiki
  %(prog)s /path/to/model/dir damaging frwiki --bucket custom-bucket
  %(prog)s model.bin goodfaith enwiki --config-file /custom/config.cfg --no-publish""",
    )

    parser.add_argument("model_path", help="Path to model file or directory to upload")
    parser.add_argument("model_type", help="Type of model (e.g., goodfaith, damaging)")
    parser.add_argument("model_lang", help="Language of model (e.g., enwiki, frwiki)")

    parser.add_argument(
        "--bucket",
        "-b",
        default="wmf-ml-models",
        help="S3 bucket name (default: %(default)s)",
    )
    parser.add_argument(
        "--config-file",
        "-c",
        default="/etc/s3cmd/cfg.d/ml-team.cfg",
        help="S3 config file path (default: %(default)s)",
    )
    parser.add_argument(
        "--no-publish", action="store_true", help="Skip the local publishing step"
    )

    args = parser.parse_args()

    # Validate config file exists
    if not os.path.exists(args.config_file):
        print(f"ERROR: Config file not found: {args.config_file}")
        sys.exit(1)

    timestamp = datetime.now().strftime("%Y%m%d%H%M%S")

    try:
        uploader = S3ModelUploader(args.config_file)
        print(
            f"UPLOADING {args.model_path} to "
            f"s3://{args.bucket}/{args.model_type}/{args.model_lang}/{timestamp}"
        )
        uploader.upload(
            args.model_path, args.model_type, args.model_lang, args.bucket, timestamp
        )
        # Ask about local publishing (unless --no-publish flag is used)
        if not args.no_publish:
            response = input(
                "Do you want to make this model downloadable at "
                f"{PUBLISHED_MODELS_URL} (publicly)? [y/N]: "
            )
            if response.lower() in ["y", "yes"]:
                if uploader.publish_locally(
                    args.model_path, args.model_type, args.model_lang, timestamp
                ):
                    print(f"Model publish to {PUBLISHED_MODELS_URL} was successful!")
                else:
                    print(
                        f"Failed to publish to {PUBLISHED_MODELS_URL}, "
                        "but S3 upload was successful."
                    )

    except Exception as e:
        print(f"ERROR: {e}", file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()
