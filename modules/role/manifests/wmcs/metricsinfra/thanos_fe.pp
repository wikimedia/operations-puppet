# SPDX-License-Identifier: Apache-2.0
class role::wmcs::metricsinfra::thanos_fe {
    include profile::wmcs::metricsinfra::thanos_query
    include profile::wmcs::metricsinfra::thanos_rule
    include profile::wmcs::metricsinfra::prometheus_configurator
}
