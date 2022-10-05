# SPDX-License-Identifier: Apache-2.0
class profile::prometheus::logstash_exporter {
    class { '::prometheus::logstash_exporter': }
}
