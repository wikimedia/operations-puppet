#!/usr/bin/python3
# SPDX-License-Identifier: Apache-2.0

# Print PromQL queries info from Apache access logs

# To run unit tests: python3 -m unittest query-log-explore.py

import argparse
import fileinput
import os
import re
import sys
import unittest
from collections import namedtuple
from datetime import datetime, timedelta
from urllib.parse import parse_qs, unquote, urlparse

Record = namedtuple(
    "Record", ("start_time", "end_time", "query", "ts", "http_status", "ua")
)


def url_to_metrics_query(url):
    parsed_url = urlparse(url)
    qs = parse_qs(parsed_url.query)

    # Instant query
    if "time" in qs:
        time_str = qs.get("time", [""])[0]

        start_time = datetime.fromtimestamp(float(time_str))
        end_time = datetime.fromtimestamp(float(time_str))
    # Range query
    elif "start" in qs and "end" in qs:
        start_time_str = qs.get("start", [""])[0]
        end_time_str = qs.get("end", [""])[0]

        start_time = datetime.fromtimestamp(float(start_time_str))
        end_time = datetime.fromtimestamp(float(end_time_str))
    else:
        raise ValueError("No 'time' or 'start'/'end' qs params found")

    if "match[]" in qs:
        metrics_query = qs.get("match[]", [""])[0]
        metrics_query = unquote(metrics_query)
    elif "query" in qs:
        metrics_query = qs.get("query", [""])[0]
        metrics_query = metrics_query.replace("\n", "")
        metrics_query = metrics_query.replace("  ", "")
    else:
        raise ValueError("No 'match[]' or 'query' qs params found")

    return start_time, end_time, metrics_query


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

    if not re.search("/(query_range|series)", url):
        return None

    start_time, end_time, metrics_query = url_to_metrics_query(url)

    ts = parts[0]
    http_status = parts[3].split("/", 1)[-1]
    ua = parts[11]

    return Record(start_time, end_time, metrics_query, ts, http_status, ua)


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        prog=os.path.basename(sys.argv[0]),
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
        try:
            r = line_to_record(line)
            if r is None:
                continue
        except ValueError as e:
            print(f"{e!r} while parsing {line!r}")
            continue

        dur = r.end_time - r.start_time
        if dur >= threshold:
            print(f"{r.ts} {dur} {r.query!r} (replied {r.http_status} to {r.ua})")

    return 0


if __name__ == "__main__":
    sys.exit(main())


class TestUrlToMetricsQuery(unittest.TestCase):
    parse_ok = [
        {
            "url": "http://thanos-query.discovery.wmnet/api/v1/query_range?"
            "query=sum%28max+by+%28type%29+%28log_w3c_networkerror_type_doc_count%7Btype%3D~%22tcp.timed_out%7Ctcp.address_unreachable%22%7D%29%29%2F60"  # noqa: E501
            "&start=1712534400.0&end=1712534468&step=60",
            "start": datetime(2024, 4, 8, 2, 0),
            "end": datetime(2024, 4, 8, 2, 1, 8),
            "query": 'sum(max by (type) (log_w3c_networkerror_type_doc_count{type=~"tcp.timed_out|tcp.address_unreachable"}))/60',  # noqa: E501
        },
        {
            "url": "http://thanos-query.discovery.wmnet/api/v1/series?"
            "match%5B%5D=container_spec_memory_limit_bytes%7Bnamespace%3D%22machinetranslation%22%2C%20site%3D~%22(codfw%7Ceqiad)%22%2C%20prometheus%3D%22k8s%22%7D"  # noqa: E501
            "&end=1712553249&start=1712531649",
            "start": datetime(2024, 4, 8, 1, 14, 9),
            "end": datetime(2024, 4, 8, 7, 14, 9),
            "query": 'container_spec_memory_limit_bytes{namespace="machinetranslation", site=~"(codfw|eqiad)", prometheus="k8s"}',  # noqa: E501
        },
    ]

    parse_errors = [
        "invalid_url",
        "http://valid.url/but/no/params",
    ]

    def test_parse_ok(self):
        for case in self.parse_ok:
            start, end, query = url_to_metrics_query(case["url"])
            self.assertEqual(start, case["start"])
            self.assertEqual(end, case["end"])
            self.assertEqual(query, case["query"])

    def test_parse_errors(self):
        for case in self.parse_errors:
            with self.assertRaises(ValueError):
                url_to_metrics_query(case)
