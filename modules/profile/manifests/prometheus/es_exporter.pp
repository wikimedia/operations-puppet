# SPDX-License-Identifier: Apache-2.0
# Prometheus Elasticsearch Query Exporter.

class profile::prometheus::es_exporter {
    class { 'prometheus::es_exporter': }
}
