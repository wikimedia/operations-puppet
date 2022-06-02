# SPDX-License-Identifier: Apache-2.0
# == Class: query_service::packages
#
# Provisions Query service package and dependencies.
#
class query_service::packages {
    # with multi instance, this package is overkill
    package { 'prometheus-blazegraph-exporter':
        ensure => absent,
    }
}
