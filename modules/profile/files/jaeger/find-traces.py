#!/usr/bin/python3
# SPDX-License-Identifier: Apache-2.0

import argparse
from datetime import datetime, timedelta

from opensearchpy import OpenSearch

JAEGER_UI_URL = "https://trace.wikimedia.org/trace"


class OrphanTraces(object):
    """Find orphan traces. See also https://phabricator.wikimedia.org/T372411"""

    q = {
        "query": {
            "bool": {
                "must_not": [
                    # only root traces
                    {
                        "nested": {
                            "path": "references",
                            "query": {"match": {"references.refType": "CHILD_OF"}},
                        }
                    },
                    # Envoy received a trace from an app, without any other trace context attached.
                    # This should be either healthchecks (which we should filter) or uninstrumented
                    # user traffic
                    {"match_phrase": {"tag.upstream_cluster@name": "local_service"}},
                    {"prefix": {"tag.upstream_cluster": "LOCAL_"}},
                ]
            }
        }
    }

    def query(self):
        return self.q

    def format(self, results):
        hits = results["hits"]["hits"]
        trace_count = {}
        traceid_samples = {}

        for hit in hits:
            doc = hit["_source"]
            try:
                namespace = doc["process"]["tag"]["k8s@namespace@name"]
                traceid = doc["traceID"]
            except KeyError:
                continue
            trace_count[namespace] = trace_count.setdefault(namespace, 0) + 1
            if namespace not in traceid_samples:
                traceid_samples[namespace] = traceid

        lines = []
        for namespace, count in sorted(
            trace_count.items(), key=lambda x: x[1], reverse=True
        ):
            lines.append(
                f"{namespace} {count} {JAEGER_UI_URL}/{traceid_samples[namespace]}"
            )

        return lines


# Function to generate a list of indices based on the look-back period and start_date
def generate_indices(prefix, start_date, days):
    indices = []
    for i in range(days):
        date_suffix = (start_date - timedelta(days=i)).strftime("%Y.%m.%d")
        index_name = f"{prefix}-{date_suffix}"
        indices.append(index_name)
    return indices


def main():
    parser = argparse.ArgumentParser(
        description="Run and report queries on jaeger storage."
    )
    parser.add_argument(
        "--days", type=int, default=3, help="Number of days to look back (default: 3)"
    )
    parser.add_argument(
        "--prefix",
        type=str,
        default="jaeger-span",
        help="Prefix of the indices (default: jaeger-span)",
    )
    parser.add_argument(
        "--start-date",
        type=str,
        help="Start date in YYYY-MM-DD format (default: today)",
    )
    parser.add_argument(
        "--url",
        type=str,
        default="http://localhost:9200",
        help="API url to query (default: http://localhost:9200)",
    )

    args = parser.parse_args()

    if args.start_date:
        start_date = datetime.strptime(args.start_date, "%Y-%m-%d").date()
    else:
        start_date = datetime.utcnow().date()
    indices = generate_indices(args.prefix, start_date, args.days)

    search = OrphanTraces()
    es = OpenSearch([args.url])
    response = es.search(index=",".join(indices), body=search.query())

    for i in search.format(response):
        print(i)


if __name__ == "__main__":
    main()
