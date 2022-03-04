#!/usr/bin/env python3
# SPDX-License-Identifier: Apache-2.0
"""
Locate Cloud VPS hiera files where the relevant VPS instances do not exist.
"""
import pathlib
import requests


def main():
    projects = [
        project
        for project in pathlib.Path("hieradata/cloud/eqiad1/").iterdir()
        if project.is_dir()
    ]
    for project in projects:
        response = requests.get(
            f"https://openstack-browser.toolforge.org/api/dsh/project/{project.name}"
        )
        if response.status_code == 500:
            print(project)
            continue
        project_servers = [x.split(".")[0] for x in response.text.split("\n")]
        for file in project.glob("hosts/*.yaml"):
            if file.name.removesuffix(".yaml") not in project_servers:
                print(file)


if __name__ == "__main__":
    main()
