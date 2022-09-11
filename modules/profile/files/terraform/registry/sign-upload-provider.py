#!/usr/bin/python3
# SPDX-License-Identifier: Apache-2.0
"""
Signs and uploads a Terraform provider binary. This is intended to be
ran on your laptop.
"""

import json
import subprocess
import sys
from argparse import ArgumentParser, Namespace
from pathlib import Path
from tempfile import TemporaryDirectory
from zipfile import ZipFile


def get_args() -> Namespace:
    """Parse arguments"""
    parser = ArgumentParser(description=__doc__)
    parser.add_argument("provider")
    parser.add_argument("file", type=Path)
    parser.add_argument("version")
    parser.add_argument("signing_key")
    parser.add_argument("--os", default="linux")
    parser.add_argument("--arch", default="amd64")
    parser.add_argument(
        "--destination-host", default="tf-registry-1.terraform.eqiad1.wikimedia.cloud"
    )
    parser.add_argument("--registry-base-path", default="/srv/terraform-registry")
    parser.add_argument("--registry-base-url", default="https://terraform.wmcloud.org")
    return parser.parse_args()


def main():
    args = get_args()

    filename = (
        f"terraform-provider-{args.provider}_{args.version}_{args.os}_{args.arch}"
    )

    file_base_path = (
        f"files/providers/{args.provider}/{args.version}/{args.os}/{args.arch}"
    )

    print("retrieving current metadata, if it exists")
    metadata_str = subprocess.check_output(
        [
            "/usr/bin/ssh",
            args.destination_host,
            f"cat {args.registry_base_path}/config/{args.provider}.json || echo does-not-exist",
        ]
    ).decode("utf-8")

    if metadata_str.strip() == "does-not-exist":
        metadata = {"versions": []}
    else:
        metadata = json.loads(metadata_str)

    version_data = {
        "version": args.version,
        # TODO
        "protcols": ["6.0"],
        "platforms": [],
    }

    existing_version_data = [
        version
        for version in metadata["versions"]
        if version["version"] == args.version
    ]
    if len(existing_version_data) == 1:
        version_data = existing_version_data[0]
        metadata["versions"].remove(version_data)

        if [
            platform
            for platform in version_data["platforms"]
            if platform["os"] == args.os and platform["arch"] == args.arch
        ]:
            print(
                "ERROR: this version already exists in the registry for the given os and arch"
            )
            sys.exit(1)

    with TemporaryDirectory() as dir:
        path = Path(dir)
        with ZipFile(path / f"{filename}.zip", "w") as zip:
            zip.write(args.file, filename)
        print(f"wrote zip file to {dir}/{filename}.zip")

        shasum_file = path / f"{filename}_SHA256SUMS"
        with shasum_file.open("w") as f:
            subprocess.check_call(
                ["/bin/sh", "-c", f"cd {dir} && /usr/bin/sha256sum {filename}.zip"],
                stdout=f,
            )
        print(f"wrote shasums to {shasum_file}")

        subprocess.check_call(
            [
                "/usr/bin/gpg",
                "--local-user",
                args.signing_key,
                "--detach-sign",
                f"{shasum_file}",
            ]
        )
        print("signed shasums, copying files to server")

        server_base_path = f"{args.registry_base_path}/{file_base_path}"
        subprocess.check_call(
            ["/usr/bin/ssh", args.destination_host, f"mkdir -pv {server_base_path}"]
        )
        for file in [
            f"{filename}.zip",
            f"{filename}_SHA256SUMS",
            f"{filename}_SHA256SUMS.sig",
        ]:
            subprocess.check_call(
                [
                    "/usr/bin/scp",
                    "-r",
                    path / file,
                    f"{args.destination_host}:{server_base_path}/{file}",
                ]
            )

    print("updating metadata")
    download_base_url = f"{args.registry_base_url}/{file_base_path}"
    platform_data = {
        "os": args.os,
        "arch": args.arch,
        "filename": f"{filename}.zip",
        "download_url": f"{download_base_url}/{filename}.zip",
        "shasums_url": f"{download_base_url}/{filename}_SHA256SUMS",
        "shasums_signature_url": f"{download_base_url}/{filename}_SHA256SUMS.sig",
        "signing_keys": {
            "gpg_public_keys": [
                {
                    "key_id": args.signing_key,
                    "ascii_armor": subprocess.check_output(
                        ["/usr/bin/gpg", "--export", "-a", args.signing_key]
                    ).decode("utf-8"),
                }
            ],
        },
    }

    version_data["platforms"].append(platform_data)
    metadata["versions"].append(version_data)

    subprocess.run(
        [
            "/usr/bin/ssh",
            args.destination_host,
            f"cat > {args.registry_base_path}/config/{args.provider}.json",
        ],
        input=json.dumps(metadata, indent=2).encode("utf-8"),
    )


if __name__ == "__main__":
    main()
