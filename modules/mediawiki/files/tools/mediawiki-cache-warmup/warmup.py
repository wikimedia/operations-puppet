#!/usr/bin/python3
# SPDX-License-Identifier: Apache-2.0
import argparse
import dataclasses
import datetime
import heapq
import operator
import queue
import random
import re
import sys
import threading
from os.path import exists
from typing import Any, Dict, List, Optional, TextIO, Tuple
from urllib import parse

import requests
import urllib3
from requests import adapters

try:
    from kubernetes import client, config

    has_k8s = True
except ImportError:
    has_k8s = False


@dataclasses.dataclass
class Wiki:
    """Represents a single wiki, pulled from sitematrix data."""

    dbname: str
    url: str
    host: str = dataclasses.field(init=False)
    mobile_host: Optional[str] = dataclasses.field(init=False)

    def __post_init__(self) -> None:
        host = parse.urlparse(self.url).hostname
        if host is None:
            raise ValueError(self.url)
        self.host = host

        try:
            subdomain, domain, tld = self.host.rsplit(".", 2)
        except ValueError:  # Tuple unpacking raises ValueError if there's only one dot in the FQDN.
            subdomain = None
            domain, tld = self.host.rsplit(".", 1)

        if self.dbname in {"labswiki", "labtestwiki", "loginwiki"}:
            self.mobile_host = None
        elif not subdomain or subdomain == "www":
            # Examples: wikisource.org -> m.wikisource.org, www.wikidata.org -> m.wikidata.org.
            self.mobile_host = f"m.{domain}.{tld}"
        else:
            # Example: en.wikipedia.org -> en.m.wikipedia.org.
            self.mobile_host = f"{subdomain}.m.{domain}.{tld}"


@dataclasses.dataclass
class Request:
    """Represents an HTTP request that could be made to one or more target hosts."""

    method: str
    url: str

    def __str__(self) -> str:
        return f"{self.method} {self.url}"


@dataclasses.dataclass
class Task:
    """Represents a single HTTP request to be made to a particular target host."""

    target: str
    method: str
    url: str


class Stats:
    """Thread-safe statistics collector."""

    def __init__(self) -> None:
        self._queue = queue.Queue()  # type: queue.Queue[Tuple[Task, float]]
        self._start_time = datetime.datetime.now()

    def update(self, task: Task, duration_sec: float) -> None:
        """Update the statistics to indicate that `task` completed in `duration_sec` seconds.

        This method may be safely called from multiple threads.
        """
        self._queue.put((task, duration_sec))

    def print(self) -> None:
        """Compile the statistics and print a summary to stdout.

        This method should be called only once, and only when update() will no longer be called from
        any thread.
        """
        wall_seconds = (datetime.datetime.now() - self._start_time).total_seconds()

        task_durations: List[Tuple[Task, float]] = []
        while True:
            try:
                task_durations.append(self._queue.get_nowait())
            except queue.Empty:
                break

        count = len(task_durations)
        fastest = min(sec for req, sec in task_durations)
        average = sum(sec for req, sec in task_durations) / count
        wall_of_shame = heapq.nlargest(5, task_durations, key=operator.itemgetter(1))

        print("Statistics:")
        print(f"  Wall time: {wall_seconds * 1000:.1f} ms")
        print(f"  Count: {count} requests")
        print(f"  Fastest: {fastest * 1000:.1f} ms")
        print(f"  Average: {average * 1000:.1f} ms")
        print()
        print(f"Slowest {len(wall_of_shame)} requests:")
        for task, duration in wall_of_shame:
            print(f" - {duration * 1000:.1f} ms ({task.target}) {task.url}")


def get_large_wikis() -> List[Wiki]:
    """Query noc.wm.o and meta.wm.o for the dbnames and hostnames of all large wikis."""
    response = requests.get("https://noc.wikimedia.org/conf/dblists/large.dblist")
    response.raise_for_status()
    large_wiki_dbnames = {line for line in response.text.splitlines() if not line.startswith("#")}

    response = requests.get(
        "https://meta.wikimedia.org/w/api.php",
        params={
            "format": "json",
            "action": "sitematrix",
            "smlangprop": "site",
            "smsiteprop": "url|dbname",
        },
    )
    response.raise_for_status()
    sitematrix = response.json()["sitematrix"]

    del sitematrix["count"]
    all_wikis = sitematrix.pop("specials")
    # Apart from "count" and "specials", which we've removed, each item in sitematrix is a language
    # group, where the key is just a number.
    for group in sitematrix.values():
        all_wikis.extend(group["site"])
    return [
        Wiki(dbname=wiki["dbname"], url=wiki["url"])
        for wiki in all_wikis
        if wiki["dbname"] in large_wiki_dbnames
    ]


def expand_urls(f: TextIO) -> List[Request]:
    """Read the URL template file and expand it into a full list of Requests for all large wikis."""
    large_wikis = get_large_wikis()
    reqs = []
    for i, line in enumerate(f.readlines()):
        line = line.strip()
        if not line or line.startswith("#"):
            continue

        if " " in line:
            method, url = line.split()
            if method.upper() not in {"GET", "HEAD", "POST", "PATCH", "PUT", "DELETE", "OPTIONS"}:
                raise ValueError(f"Invalid HTTP method '{method}' at line {i + 1} of URLs file")
        else:
            method, url = "GET", line

        if "%server" in url:
            for wiki in large_wikis:
                reqs.append(Request(method, url.replace("%server", wiki.host)))
        elif "%mobileServer" in url:
            for wiki in large_wikis:
                if wiki.mobile_host:
                    reqs.append(Request(method, url.replace("%mobileServer", wiki.mobile_host)))
        else:
            reqs.append(Request(method, url))
    return reqs


def get_endpoint_hostports(core: "client.CoreV1Api", namespace: str) -> List[str]:
    """Fetch all host:port endpoints on the inbound TLS service in `namespace`."""
    resp = core.list_namespaced_endpoints(namespace=namespace)
    if resp.items is None:
        return []
    # Matches the Endpoints object name structure we use for the inbound TLS service.
    pattern = re.compile("mediawiki-(main|pinkunicorn)-tls-service")
    targets = []
    for endpoints in resp.items:
        if pattern.match(endpoints.metadata.name) is None:
            continue
        # In practice, subsets will always be non-empty ...
        for subset in endpoints.subsets:
            # ... and should have only one port configured.
            if len(subset.ports) != 1:
                raise ValueError(
                    f"{endpoints.metadata.name} contains an endpoint subset with "
                    "{len(subset.ports)} ports (want: exactly 1 port)."
                )
            port = subset.ports[0].port
            for address in subset.addresses:
                targets.append(f"{address.ip}:{port}")
            num_not_ready = (
                0 if subset.not_ready_addresses is None else len(subset.not_ready_addresses)
            )
            if num_not_ready > 0:
                print(
                    f"WARNING: Skipping {num_not_ready} endpoint addresses on "
                    "{endpoints.metadata.name} that are currently not ready."
                )
    return targets


def do_requests(
    targets: List[str],
    reqs: List[Request],
    global_concurrency: int,
    target_concurrency: int,
) -> Stats:
    """Send each of `reqs` to each of `targets` and return the aggregated timing statistics.

    No more than `global_concurrency` requests are in flight at any time, and no more than
    `target_concurrency` requests are in flight to any single target host at any time.
    """
    target_semaphores = {target: threading.Semaphore(target_concurrency) for target in targets}

    # Assemble all the requests we'll make and place them on a work queue. We build out a list of
    # tasks first, so that we can shuffle them before putting them on the queue.
    #
    # Shuffling serves two purposes: it spreads out the requests evenly across multiple target hosts
    # (limiting contention on each target_semaphore), and it reduces the chance of many target hosts
    # concurrently processing the same URL (limiting contention on shared backend resources).
    tasks = [Task(target, request.method, request.url) for request in reqs for target in targets]
    random.shuffle(tasks)
    work_queue = queue.Queue()  # type: queue.Queue[Task]
    for task in tasks:
        work_queue.put(task)

    # TODO: `session` could be a wmflib.requests.http_session, except that we set custom values for
    #  pool_connections and pool_maxsize, because we have so many worker threads. That means we have
    #  to overwrite the session's HTTPAdapter with our own, so we don't get much benefit from
    #  wmflib. We could start using it, if we add pool_connections and pool_maxsize args to wmflib.
    #  (We don't need its retry feature for warmups, though.)
    # TODO: By experiment, 50 is as high as we can safely set pool_connections, due to a urllib3
    #  thread safety bug: https://github.com/urllib3/urllib3/issues/1252. Once we've upgraded to
    #  urllib3 >=2.0.0, we can increase both parameters here (and therefore also increase
    #  global_concurrency, when in "clone" mode). Ideally pool_connections should be len(targets)
    #  and max_poolsize should be target_concurrency.
    session = requests.Session()
    session.headers = {"User-Agent": "warmup.py (sre@wikimedia.org)"}
    session.verify = False  # Don't verify TLS certs, since we don't have certs for mwNNNN names.
    urllib3.disable_warnings()  # And don't warn about not verifying TLS certs.
    adapter = adapters.HTTPAdapter(pool_connections=50, pool_maxsize=100)
    session.mount("http://", adapter)
    session.mount("https://", adapter)

    stats = Stats()
    for i in range(global_concurrency):
        threading.Thread(
            target=worker,
            args=(work_queue, session, target_semaphores, stats),
            name=f"Worker {i + 1}",
        ).start()
    work_queue.join()
    return stats


def worker(
    work_queue: "queue.Queue[Task]",
    session: requests.Session,
    target_semaphores: Dict[str, threading.Semaphore],
    stats: Stats,
) -> None:
    """Process the work queue, sending HTTP requests until the queue is empty."""
    while True:
        try:
            task = work_queue.get_nowait()
        except queue.Empty:
            return

        if not target_semaphores[task.target].acquire(blocking=False):
            # This target is already at max concurrency. Put this task back at the end of the queue
            # and get another. (In case we're near the end of the queue, call put() before
            # task_done(). That way the task count never reaches zero, in which case join() would
            # return prematurely.)
            work_queue.put(task)
            work_queue.task_done()
            continue

        duration = do_task(task, session)
        target_semaphores[task.target].release()
        stats.update(task, duration.total_seconds())
        work_queue.task_done()


def do_task(task: Task, session: requests.Session) -> datetime.timedelta:
    """Perform an HTTP request, discard the response, and return the amount of time it took."""
    parsed_url = parse.urlparse(task.url)
    # Move the URL's virtual host into the Host header, and substitute the target host:port.
    vhost = parsed_url.hostname
    parsed_url = parsed_url._replace(netloc=task.target)
    return session.request(task.method, parsed_url.geturl(), headers={"Host": vhost}).elapsed


def print_prefix(items: List[Any], limit: Optional[int] = None):
    """Print up to limit of items, reporting the number elided."""
    for item in items if limit is None else items[:limit]:
        print(f" {item}")
    if limit is not None and len(items) > limit:
        print(f" ... (and {len(items) - limit} more)")


def print_summary(args: argparse.Namespace, reqs: List[Request], targets: List[str]):
    """Print a summary of warmup requests and targets."""
    message_prefix = "Would send" if args.dry_run else "Sending"
    print(f"{message_prefix} {len(reqs)} requests to each of {len(targets)} targets.")
    limit = None if args.full else 10
    print("Requests:")
    print_prefix(reqs, limit=limit)
    print("Targets:")
    print_prefix(targets, limit=limit)
    print()


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "file",
        type=argparse.FileType("r"),
        # The text files use "%server". The `help` arg is a %-format string, so % signs are escaped.
        help="Path to a text file containing a newline-separated list of URLs. Entries may use "
        "%%server or %%mobileServer.",
    )
    parser.add_argument(
        "--dry-run",
        help=(
            "do not send requests; exit after printing a sample of the URL and target lists that "
            "would have been used"
        ),
        action="store_true",
    )
    parser.add_argument(
        "--full",
        help="print full URL and target lists, rather than a sample",
        action="store_true",
    )

    subparsers = parser.add_subparsers(title="commands", dest="command")

    spread = subparsers.add_parser("spread", help="distribute URLs via load balancer")
    spread.add_argument("target", help="target host:port, e.g. mw-web.svc.codfw.wmnet:4450")

    clone = subparsers.add_parser("clone", help="send each URL to each mediawiki kubernetes pod")
    clone.add_argument("cluster", help="target kubernetes cluster, e.g. codfw")
    clone.add_argument("namespace", help="target kubernetes namespace, e.g. mw-web")

    args = parser.parse_args()
    reqs = expand_urls(args.file)
    if args.command == "spread":
        targets = [args.target]
        concurrency = {"global_concurrency": 1000, "target_concurrency": 1000}
    elif args.command == "clone":
        if not has_k8s:
            print(
                "'clone' now requires a kubernetes client. Is this not a deployment server?"
                " (T369921)"
            )
            return 1
        config_path = f"/etc/kubernetes/{args.namespace}-{args.cluster}.config"
        if not exists(config_path):
            print(
                f"'clone' now requires kubernetes client configuration, but {config_path} does not "
                "exist. Is this not a deployment server? (T369921)"
            )
            return 1
        core = client.CoreV1Api(client.ApiClient(config.load_kube_config(config_path)))
        targets = get_endpoint_hostports(core, args.namespace)
        if not targets:
            print(f"No targets found in namespace {args.namespace} in cluster {args.cluster}.")
            return 1
        # target_concurrency is lower in this mode, because each target is a single machine, rather
        # than a load-balanced group like in spread mode. But global_concurrency can eventually be
        # higher than this; see the TODO comment in do_requests. (Until then, target_concurrency has
        # no effect; no more than 50 requests can be in flight anyway!)
        concurrency = {"global_concurrency": 50, "target_concurrency": 150}
    else:
        parser.print_usage()
        return 1

    print_summary(args, reqs, targets)

    if not args.dry_run:
        do_requests(targets, reqs, **concurrency).print()

    return 0


if __name__ == "__main__":
    sys.exit(main())
