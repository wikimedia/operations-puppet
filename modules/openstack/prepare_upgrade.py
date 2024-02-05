#!/usr/bin/env python3
# SPDX-License-Identifier: Apache-2.0

"""
Duplicate a bunch of files to prepare for an OpenStack version upgrade,
and also take care of replacing the version name in the file content.
https://wikitech.wikimedia.org/wiki/Portal:Cloud_VPS/Admin/Openstack_upgrade
"""

import os
import sys
import shutil
import re


def main():
    if len(sys.argv) != 3:
        print(
            "Usage: python prepare_upgrade.py old_version new_version\n"
            "Example: python prepare_upgrade.py zed antelope"
        )
        return

    old_version, new_version = sys.argv[1], sys.argv[2]

    print(
        f"Old Version: {old_version}, New Version: {new_version}"
    )

    script_dir = os.path.dirname(os.path.abspath(__file__))

    files_to_copy = [
        (
            os.path.join(root, filename),
            os.path.join(
                script_dir,
                os.path.relpath(os.path.join(root, filename), script_dir)
                .replace(old_version, new_version),
            ),
        )
        for root, _, files in os.walk(script_dir)
        for filename in files
        if includes_full_word(
            old_version,
            os.path.relpath(os.path.join(root, filename), script_dir),
        )
    ]

    copied_files = copy_files(files_to_copy)

    print("\nCopied files:")
    for filename in copied_files:
        print(os.path.relpath(filename, script_dir))

    print("\nReplacing versions in copied files...")
    files_with_replacements = replace_versions_in_copied_files(
        copied_files, old_version, new_version
    )

    print("\nFiles where version was replaced:")
    for filename in files_with_replacements:
        print(os.path.relpath(filename, script_dir))


def includes_full_word(word, text):
    return re.search(rf"\b{re.escape(word)}\b", text) is not None


def copy_files(files_to_copy):
    copied_files = []

    for old_path, new_path in files_to_copy:
        if not os.path.isdir(old_path):
            os.makedirs(
                os.path.dirname(new_path), exist_ok=True
            )  # Ensure the destination directory exists
            shutil.copy2(old_path, new_path)
            copied_files.append(new_path)
        else:
            shutil.copytree(old_path, new_path, dirs_exist_ok=True)
            copied_files.extend(
                [
                    os.path.join(root, filename)
                    for root, _, filenames in os.walk(new_path)
                    for filename in filenames
                ]
            )

    return copied_files


def replace_versions_in_copied_files(
    copied_files, old_version, new_version
):
    files_with_replacements = []

    for file_path in copied_files:
        with open(file_path, "r+") as file:
            content = file.read()
            updated_content = re.sub(
                rf"\b{re.escape(old_version)}\b",
                new_version,
                content,
            )
            if content != updated_content:
                file.seek(0)
                file.write(updated_content)
                file.truncate()
                files_with_replacements.append(file_path)

    return files_with_replacements


if __name__ == "__main__":
    main()
