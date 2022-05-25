# SPDX-License-Identifier: Apache-2.0
# == Class: opensearch::packages
#
# Provisions OpenSearch package and dependencies.
#
class opensearch::packages (
    String  $package_name,
    Boolean $send_logs_to_logstash,
) {
    include ::java::tools # lint:ignore:wmf_styleguide

    package { 'opensearch':
        ensure => present,
        name   => $package_name,
    }
}
