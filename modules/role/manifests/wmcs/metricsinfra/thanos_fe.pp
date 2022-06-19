# SPDX-License-Identifier: Apache-2.0
class role::wmcs::metricsinfra::thanos_fe {
    system::role { $name:
        description => 'CloudVPS monitoring infrastructure Thanos frontend'
    }

    include ::profile::wmcs::metricsinfra::thanos_query
}
