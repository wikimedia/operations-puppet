#!/usr/bin/python3
# SPDX-License-Identifier: Apache-2.0
import sys
import requests
import os
from prometheus_client import CollectorRegistry, Gauge, push_to_gateway


class GrafanaGraphite(object):

    def fetch_dashboards(self, HOST):
        s = requests.Session()
        searchresults = s.get('%s/api/search?limit=5000&query=&' % (HOST,))
        searchresults.raise_for_status()

        for d in searchresults.json():
            dashboard = s.get('%s/api/dashboards/uid/%s' % (HOST, d['uid']))
            dashboard.raise_for_status()
            yield dashboard.json()["dashboard"]

    def extract_graphite_queries(self, dashboard):

        graphite_queries = []

        # Walk a dashboard looking for either a null datasource (signifying default
        # datasource of graphite) or datasource type graphite.
        if "panels" not in dashboard:
            return []

        for panel in dashboard["panels"]:

            # If the datasource is null, assume it is graphite (default)
            try:
                if panel["datasource"] is None:
                    graphite_datasource = True
                elif panel["datasource"]["type"] == "graphite":
                    graphite_datasource = True
                else:
                    graphite_datasource = False
            except (KeyError, TypeError):
                continue

            if not graphite_datasource:
                continue

            # ignore panel types without queries
            if panel["type"] in ["row", "text", "dashlist"]:
                continue

            for target in panel.get("targets", []):
                if "datasource" not in target:
                    continue

                if target["datasource"]["type"] != "graphite":
                    continue

                # Try targetFull first to capture full queries instead
                # of refIds like #A #B
                if "targetFull" in target:
                    graphite_queries.append(
                        target["targetFull"]
                    )
                elif "target" in target:
                    graphite_queries.append(target["target"])

        return graphite_queries


def main():
    HOST = os.environ["GRAFANA_URL"]
    PUSHGW = os.environ["PUSHGATEWAY_URL"]

    c = GrafanaGraphite()
    dashboards = c.fetch_dashboards(HOST)

    registry = CollectorRegistry()
    # this will be a gauge representing the number of graphite queries used per dashboard
    g = Gauge(
        "grafana_datasource_exporter_graphite_query_count",
        "graphite query count by dashboard",
        ["dashboard", "uid"],
        registry=registry,
    )

    for dashboard in dashboards:
        graphite_queries = c.extract_graphite_queries(dashboard)

        if len(graphite_queries) <= 0:
            continue

        # increment our gauge, including dashboard title and uid
        g.labels(dashboard=dashboard['title'], uid=dashboard['uid']).inc(
            len(graphite_queries)
        )

    push_to_gateway(
        PUSHGW,
        job="grafana_datasource_exporter",
        registry=registry
    )


if __name__ == "__main__":
    sys.exit(main())
