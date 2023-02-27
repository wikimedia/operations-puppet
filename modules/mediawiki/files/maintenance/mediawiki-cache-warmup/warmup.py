#!/usr/bin/python3
# SPDX-License-Identifier: Apache-2.0
import argparse
import dataclasses
import datetime
import heapq
import json
import operator
import queue
import random
import subprocess
import sys
import threading
from typing import Dict, List, Optional, TextIO, Tuple
from urllib import parse

import requests
import urllib3
from requests import adapters


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


def get_target_hostnames(data_center: str, cluster: str) -> List[str]:
    """Read pool status in conftool and return all pooled hostnames in the given cluster and DC."""
    selector = f"dc={data_center},cluster={cluster},service=nginx"
    command = ["confctl", "tags", selector, "--action", "get", "all"]
    confctl_stdout = subprocess.run(command, capture_output=True).stdout
    conftool_data = json.loads(confctl_stdout)
    return [host for host, state in conftool_data.items() if state["pooled"] == "yes"]


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
    # Move the URL's virtual host into the Host header, and substitute the target hostname.
    vhost = parsed_url.hostname
    parsed_url = parsed_url._replace(netloc=task.target)
    return session.request(task.method, parsed_url.geturl(), headers={"Host": vhost}).elapsed


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "file",
        type=argparse.FileType("r"),
        # The text files use "%server". The `help` arg is a %-format string, so % signs are escaped.
        help="Path to a text file containing a newline-separated list of URLs. Entries may use "
        "%%server or %%mobileServer.",
    )
    subparsers = parser.add_subparsers(title="commands", dest="command")

    spread = subparsers.add_parser("spread", help="distribute URLs via load balancer")
    spread.add_argument("target", help="target host, e.g. appservers.svc.codfw.wmnet")

    clone = subparsers.add_parser("clone", help="send each URL to each server")
    clone.add_argument("cluster", help="target cluster, e.g. appserver")
    clone.add_argument("dc", help="target data center, e.g. codfw")

    dry = subparsers.add_parser("dry", help="print list of URLs to standard out")
    dry.add_argument("--all", action="store_true", help="dump the full list of URLs")

    args = parser.parse_args()
    reqs = expand_urls(args.file)
    if args.command == "spread":
        stats = do_requests([args.target], reqs, global_concurrency=1000, target_concurrency=1000)
        stats.print()
        return 0
    elif args.command == "clone":
        targets = get_target_hostnames(args.dc, args.cluster)
        # target_concurrency is lower in this mode, because each target is a single machine, rather
        # than a load-balanced group like in spread mode. But global_concurrency can eventually be
        # higher than this; see the TODO comment in do_requests. (Until then, target_concurrency has
        # no effect; no more than 50 requests can be in flight anyway!)
        stats = do_requests(targets, reqs, global_concurrency=50, target_concurrency=150)
        stats.print()
        return 0
    elif args.command == "dry":
        print(f"Would send {len(reqs)} URLs:")
        random.shuffle(reqs)
        for request in reqs if args.all else reqs[:20]:
            print(f"{request.method} {request.url}")
        if not args.all and len(reqs) > 20:
            print("...")
        return 0
    else:
        parser.print_usage()
        return 1


if __name__ == "__main__":
    sys.exit(main())
