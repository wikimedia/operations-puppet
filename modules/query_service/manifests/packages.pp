# == Class: query_service::packages
#
# Provisions Query service package and dependencies.
#
class query_service::packages {

    # Move to profile/query_service
    # include java::tools

    require_package('openjdk-8-jdk')

    # with multi instance, this package is overkill
    package { 'prometheus-blazegraph-exporter':
        ensure => absent,
    }
}
