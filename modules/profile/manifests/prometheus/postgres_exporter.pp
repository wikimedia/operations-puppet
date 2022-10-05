# SPDX-License-Identifier: Apache-2.0
class profile::prometheus::postgres_exporter {
    class { 'prometheus::postgres_exporter': }
}
