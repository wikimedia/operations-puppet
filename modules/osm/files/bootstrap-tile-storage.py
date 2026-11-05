#!/usr/bin/env python3
# SPDX-License-Identifier: Apache-2.0
"""
Ad-hoc tile invalidation (T440080).

Streams the object listing of a Swift container (tegola tile cache), extracts
z/x/y tile coordinates from object names and sends `maps.tiles_change` events
to EventGate, marking each tile as "expired".

Credentials are read from env vars (ST_AUTH, ST_USER, ST_KEY).
"""

import json
import logging
import re
import socket
import sys
import time

import click
import requests
from requests.adapters import HTTPAdapter
from swiftclient.client import Connection
from urllib3.util.retry import Retry

TILE_RE = re.compile(r"(\d+)/(\d+)/(\d+)")

log = logging.getLogger("invalidate-tiles")


def iter_swift_pages(conn, container, prefix, marker, end_marker, page_size):
    """Yield lists of object names, one Swift listing page at a time."""
    while True:
        _headers, objects = conn.get_container(
            container,
            marker=marker,
            end_marker=end_marker,
            prefix=prefix,
            limit=page_size,
            full_listing=False,
        )
        if not objects:
            return
        # Use the last item in the response (object or subdir) as the next marker.
        names = [obj["name"] for obj in objects if "name" in obj]
        yield names
        marker = objects[-1].get("name") or objects[-1].get("subdir")
        if len(objects) < page_size:
            return


def parse_tile(name):
    """Return the exact "z/x/y" from an object name, or None if it isn't a tile."""
    match = TILE_RE.search(name)
    if not match:
        return None
    z, x, y = (int(v) for v in match.groups())
    return f"{z}/{x}/{y}"


def build_event(tiles, stream, domain):
    return {
        "$schema": "/maps/tiles_change/1.0.0",
        "meta": {"stream": stream, "domain": domain},
        "changes": [{"tile": t, "state": "expired"} for t in tiles],
    }


def make_session(retries):
    session = requests.Session()
    retry = Retry(
        total=retries,
        backoff_factor=1,
        status_forcelist=(429, 500, 502, 503, 504),
        allowed_methods=frozenset(["POST"]),
        raise_on_status=False,
    )
    session.mount("https://", HTTPAdapter(max_retries=retry))
    session.mount("http://", HTTPAdapter(max_retries=retry))
    session.headers.update({"Content-Type": "application/json"})
    return session


class EventSender:
    def __init__(self, session, endpoint, events_per_request, dry_run, timeout):
        self.session = session
        self.endpoint = endpoint
        self.events_per_request = events_per_request
        self.dry_run = dry_run
        self.timeout = timeout
        self.pending = []
        self.events_sent = 0
        self.requests_sent = 0

    def add(self, event):
        self.pending.append(event)
        if len(self.pending) >= self.events_per_request:
            self.flush()

    def flush(self):
        if not self.pending:
            return
        # Always POST a JSON array of events.
        payload = json.dumps(self.pending)
        if self.dry_run:
            log.debug("dry-run, would POST: %s", payload)
        else:
            resp = self.session.post(self.endpoint, data=payload, timeout=self.timeout)
            if resp.status_code not in (201, 202):
                raise click.ClickException(
                    f"EventGate returned {resp.status_code}: {resp.text[:1000]}"
                )
        self.events_sent += len(self.pending)
        self.requests_sent += 1
        self.pending = []


@click.command(context_settings={"show_default": True})
@click.option(
    "--auth-url", envvar="ST_AUTH", required=True, help="Swift auth URL (env ST_AUTH)."
)
@click.option(
    "--user", envvar="ST_USER", required=True, help="Swift user (env ST_USER)."
)
@click.option("--key", envvar="ST_KEY", required=True, help="Swift key (env ST_KEY).")
@click.option(
    "--container",
    envvar="CACHE_CONTAINER",
    required=True,
    help="Swift container holding the tiles (env CACHE_CONTAINER).",
)
@click.option("--prefix", default=None, help="Only list objects with this prefix.")
@click.option(
    "--marker", default=None, help="Start listing after this object name (resume)."
)
@click.option(
    "--end-marker", default=None, help="Stop listing before this object name."
)
@click.option(
    "--page-size",
    default=10000,
    type=click.IntRange(1, 10000),
    help="Objects per Swift listing request.",
)
@click.option(
    "--eventgate-endpoint",
    default="https://eventgate-main.discovery.wmnet:4492/v1/events",
)
@click.option("--stream", default="maps.tiles_change", help="Event stream name.")
@click.option("--domain", default=socket.getfqdn(), help="meta.domain of the events.")
@click.option(
    "--tiles-per-event",
    default=100,
    type=click.IntRange(1),
    help="Tiles in each event's `changes` array.",
)
@click.option(
    "--events-per-request",
    default=1,
    type=click.IntRange(1),
    help="Events batched in a single POST to EventGate.",
)
@click.option(
    "--max-tiles",
    default=None,
    type=click.IntRange(1),
    help="Stop after this many tiles (useful for a canary run).",
)
@click.option(
    "--retries", default=5, type=click.IntRange(0), help="HTTP retries per POST."
)
@click.option("--timeout", default=30.0, type=float, help="HTTP timeout in seconds.")
@click.option(
    "--dry-run", is_flag=True, help="List Swift and build events, but don't POST them."
)
@click.option(
    "-v", "--verbose", is_flag=True, help="Debug logging (prints events in dry-run)."
)
def main(
    auth_url,
    user,
    key,
    container,
    prefix,
    marker,
    end_marker,
    page_size,
    eventgate_endpoint,
    stream,
    domain,
    tiles_per_event,
    events_per_request,
    max_tiles,
    retries,
    timeout,
    dry_run,
    verbose,
):
    """Send tile invalidation events for every tile object in a Swift container."""
    logging.basicConfig(
        level=logging.DEBUG if verbose else logging.INFO,
        format="%(asctime)s %(levelname)s %(message)s",
    )

    # Never let swiftclient/urllib3 debug logs leak credentials.
    logging.getLogger("swiftclient").setLevel(logging.WARNING)
    logging.getLogger("urllib3").setLevel(logging.WARNING)

    conn = Connection(authurl=auth_url, user=user, key=key, retries=5)
    sender = EventSender(
        make_session(retries),
        eventgate_endpoint,
        events_per_request,
        dry_run,
        timeout,
    )

    log.info(
        "Starting: container=%s prefix=%s marker=%s endpoint=%s stream=%s dry_run=%s",
        container,
        prefix,
        marker,
        eventgate_endpoint,
        stream,
        dry_run,
    )

    objects_seen = 0
    tiles_seen = 0
    skipped = 0
    last_marker = marker
    batch = []
    start = time.monotonic()
    done = False

    try:
        for names in iter_swift_pages(
            conn, container, prefix, marker, end_marker, page_size
        ):
            for name in names:
                objects_seen += 1
                tile = parse_tile(name)
                if tile is None:
                    skipped += 1
                    continue
                batch.append(tile)
                tiles_seen += 1
                if len(batch) >= tiles_per_event:
                    sender.add(build_event(batch, stream, domain))
                    batch = []
                if max_tiles and tiles_seen >= max_tiles:
                    done = True
                    last_marker = name
                    break

            # Flush at page boundaries so the checkpoint marker is accurate:
            # every object up to and including it has been sent.
            if batch:
                sender.add(build_event(batch, stream, domain))
                batch = []
            sender.flush()
            if not done:
                last_marker = names[-1]

            elapsed = time.monotonic() - start
            log.info(
                "checkpoint marker=%s objects=%d tiles=%d skipped=%d events=%d "
                "requests=%d rate=%.0f tiles/s",
                last_marker,
                objects_seen,
                tiles_seen,
                skipped,
                sender.events_sent,
                sender.requests_sent,
                tiles_seen / elapsed if elapsed else 0,
            )
            if done:
                log.info("Reached --max-tiles=%d, stopping.", max_tiles)
                break

    except (KeyboardInterrupt, Exception) as exc:
        log.error(
            "Aborted (%s). Unsent events were dropped; resume with --marker=%s",
            exc.__class__.__name__,
            last_marker,
        )
        if isinstance(exc, KeyboardInterrupt):
            sys.exit(130)
        raise

    log.info(
        "Done: objects=%d tiles=%d skipped=%d events=%d requests=%d in %.0fs",
        objects_seen,
        tiles_seen,
        skipped,
        sender.events_sent,
        sender.requests_sent,
        time.monotonic() - start,
    )


if __name__ == "__main__":
    main()
