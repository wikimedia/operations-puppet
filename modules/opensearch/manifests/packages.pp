# SPDX-License-Identifier: Apache-2.0
# == Class: opensearch::packages
#
# Provisions OpenSearch package and dependencies.
#
class opensearch::packages (
    Opensearch::SemVer $version,
    Boolean            $send_logs_to_logstash,
) {
    include java::tools # lint:ignore:wmf_styleguide

    package { 'opensearch':
        ensure => $version,
    }
}
