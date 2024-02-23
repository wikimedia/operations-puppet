#!/usr/bin/python3
# SPDX-License-Identifier: Apache-2.0

# Print PromQL queries info from Apache access logs

import argparse
import fileinput
import sys
from collections import namedtuple
from datetime import datetime, timedelta
from urllib.parse import parse_qs, unquote, urlparse

Record = namedtuple(
    "Record", ("start_time", "end_time", "query", "ts", "http_status", "ua")
)


# Log entries look like the following:
#
# 2024-02-07T00:00:08	256260	10.64.134.21	proxy-server/200	863	GET
# http://thanos-query.discovery.wmnet/api/v1/query_range?end=1707264000&query=histogram_quantile%280.5%2C+sum+by+%28le%29+%28rate%28cpjobqueue_normal_rule_processing_delay_bucket%7Brule%3D~%22.%2ADispatchChanges%24%22%2Crule%21~%22.%2A-partitioner-mediawiki-job-.%2A%22%2C+service%3D%22cpjobqueue%22%7D%5B15m%5D%29%29%29&start=1707263700&step=1
# -	application/json	-	10.64.0.119	Grafana/9.4.14	-	-	-	-	10.64.134.21
# 57d2905f-740e-4882-b72d-69386fde896f	-


def line_to_record(log_line):
    parts = log_line.split("\t")
    url = parts[6]
    method = parts[5]

    if method != "GET":
        return None

    parsed_url = urlparse(url)
    query_params = parse_qs(parsed_url.query)

    # Instant query
    if "time" in query_params:
        time_str = query_params.get("time", [""])[0]

        start_time = datetime.fromtimestamp(float(time_str))
        end_time = datetime.fromtimestamp(float(time_str))
    elif "start" in query_params and "end" in query_params:
        start_time_str = query_params.get("start", [""])[0]
        end_time_str = query_params.get("end", [""])[0]

        start_time = datetime.fromtimestamp(float(start_time_str))
        end_time = datetime.fromtimestamp(float(end_time_str))
    else:
        return None

    match_param_encoded = query_params.get("match[]", [""])[0]
    match_param_decoded = unquote(match_param_encoded)

    ts = parts[0]
    http_status = parts[3].split("/", 1)[-1]
    ua = parts[11]

    return Record(start_time, end_time, match_param_decoded, ts, http_status, ua)


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        prog="query-log-explore",
        formatter_class=argparse.ArgumentDefaultsHelpFormatter,
        description="Print Thanos/Prometheus query information from access logs.",
    )
    parser.add_argument(
        "--min-range",
        metavar="DURATION",
        help="Select only queries requesting more than DURATION range",
        default="5m",
    )
    parser.add_argument(
        "files",
        metavar="FILE",
        help="Read data from FILE(s). Default to stdin.",
        nargs="*",
    )
    return parser.parse_args()


def duration_to_timedelta(duration: str) -> timedelta:
    qty, unit = int(duration[:-1]), duration[-1]
    if unit == "m":
        return timedelta(minutes=qty)
    elif unit == "s":
        return timedelta(seconds=qty)
    elif unit == "d":
        return timedelta(days=qty)
    return None


def main() -> int:
    args = parse_args()

    threshold = duration_to_timedelta(args.min_range)

    for line in fileinput.input(
        files=args.files if args.files else "-", encoding="utf-8"
    ):
        if "match" not in line:
            continue

        try:
            r = line_to_record(line)
            if r is None:
                continue
        except ValueError as e:
            print(f"{e!r} while parsing {line!r}")
            continue

        dur = r.end_time - r.start_time
        if dur >= threshold:
            print(f"{r.ts} {dur} {r.query} (replied {r.http_status} to {r.ua})")

    return 0


if __name__ == "__main__":
    sys.exit(main())
