# SPDX-License-Identifier: Apache-2.0
class role::wmcs::metricsinfra::grafana {
    system::role { $name: }

    include ::profile::wmcs::metricsinfra::grafana
}
