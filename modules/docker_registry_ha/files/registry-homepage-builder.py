#!/usr/bin/env python3
# SPDX-License-Identifier: GPL-3.0

"""
Builds a homepage for a docker registry
Copyright (C) 2019 Tyler Cipriani <tcipriani@wikimedia.org>
Copyright (C) 2021 Kunal Mehta <legoktm@debian.org>

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <https://www.gnu.org/licenses/>.
"""
import argparse
import logging
import shutil
import sys
import textwrap

from datetime import datetime
from pathlib import Path

from docker_report.registry import browser

logger = logging.getLogger()


def header(title) -> str:
    return textwrap.dedent(
        """\
        <!doctype html5>
        <html>
        <head>
            <meta charset="utf-8" />
            <meta http-equiv="X-UA-Compatible" content="IE=edge">
            <title>{title}</title>
            <meta name="viewport" content="width=device-width, initial-scale=1" />
            <link rel="stylesheet" href="/style.css" type="text/css" />
        </head>
        <body>
        """.format(title=title)
    )


def footer() -> str:
    program_url = "https://gerrit.wikimedia.org/g/operations/puppet/+/refs/heads/production/modules/docker_registry_ha/files/registry-homepage-builder.py"  # noqa: E501
    return """
           <footer>Page created by <a href="{program_url}">registry-homepage-builder.py</a></footer>
           </body></html>
           """.format(program_url=program_url)


def build_index(images, timestamp) -> str:
    text = header("Wikimedia Docker - Images") + textwrap.dedent(
        """\
        <h1>Wikimedia Docker - Images</h1>
            <p class="updated">Last updated at: {timestamp}.</p>
            <ul>
        """.format(timestamp=timestamp)
    )
    for image in images:
        text += '        <li><a href="{image}/tags/">{image}</a></li>\n'.format(image=image)
    text += '    </ul>\n'
    text += footer()
    return text


def get_latest(tags) -> str:
    if len(tags) == 1:
        # If there's only one tag (like the "pause" container),
        # that's it
        return tags[0]
    # Find the highest tag that isn't "latest"
    return max(tag for tag in tags if tag != "latest")


def build_tags(image, tags, timestamp) -> str:
    # Get the highest tag that isn't "latest"
    latest = get_latest(tags)
    text = header("Wikimedia Docker - Image: {image}".format(image=image)) + textwrap.dedent(
        """\
        <h1><a href="/">Wikimedia Docker</a> - Image: {image}</h1>
        <p class="updated">Last updated at: {timestamp}.</p>
        <div class="download">
            <h2>Download:</h2>
            <code><pre>docker pull docker-registry.wikimedia.org/{image}:{latest}</pre></code>
        </div>
        <div class="tags">
            <h2>Tags:</h2>
            <ul>
        """.format(image=image, latest=latest, timestamp=timestamp)
    )
    for tag in tags:
        text += "        <li>{tag}</li>\n".format(tag=tag)
    text += "    </ul>\n</div>\n"
    text += footer()
    return text


def parse_args():
    parser = argparse.ArgumentParser()
    parser.add_argument("registry", help="URL of docker registry (without scheme)")
    parser.add_argument("path", help="Output directory", type=Path)
    parser.add_argument("--debug", action="store_true", help="Enable debugging output")
    parser.add_argument("--css", help="Path to CSS", type=Path,
                        default="/usr/local/lib/registry-homepage-builder.css")
    return parser.parse_args()


def main():
    args = parse_args()
    logging.basicConfig(level=logging.DEBUG if args.debug else logging.INFO)

    if not args.path.exists():
        logger.error("Error: Output directory %s doesn't exist.", args.path)
        sys.exit(1)
    if not args.css.is_file():
        logger.error("Error: CSS path %s doesn't exist.", args.css)
        sys.exit(1)

    registry = browser.RegistryBrowser(args.registry, logger=logger, protocol="http")
    images = []
    timestamp = datetime.utcnow().strftime("%Y-%m-%d %H:%M")
    # sort=True is very slow, for now we alphasort in get_latest()
    for image, tags in sorted(registry.get_image_tags(sort=False).items()):
        images.append(image)
        subpath = args.path / image / "tags"
        subpath.mkdir(parents=True, exist_ok=True)
        html = build_tags(image, tags, timestamp)
        (subpath / "index.html").write_text(html)
    # TODO: handle deletion of images (see T242604)
    index = build_index(images, timestamp)
    (args.path / "index.html").write_text(index)
    # Copy CSS
    shutil.copy(str(args.css), str(args.path / "style.css"))


if __name__ == "__main__":
    main()
