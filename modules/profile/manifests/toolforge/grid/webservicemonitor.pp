class profile::toolforge::grid::webservicemonitor(
    Stdlib::Fqdn $active_host = lookup('profile::toolforge::grid::webservicemonitor::active_host'),
) {
    include profile::toolforge::k8s::client

    $is_active = $active_host == $::facts['fqdn']

    # webservicemonitor stuff, previously in services nodes
    package { 'tools-manifest':
        ensure => latest,
    }

    service { 'webservicemonitor':
        ensure    => $is_active.bool2str('running', 'stopped'),
        subscribe => Package['tools-manifest'],
    }
}
