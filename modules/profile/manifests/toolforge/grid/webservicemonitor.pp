class profile::toolforge::grid::webservicemonitor(
){
    include profile::toolforge::k8s::client

    # webservicemonitor stuff, previously in services nodes
    package { 'tools-manifest':
        ensure => latest,
    }

    service { 'webservicemonitor':
        ensure    => 'running',
        subscribe => Package['tools-manifest'],
    }
}
