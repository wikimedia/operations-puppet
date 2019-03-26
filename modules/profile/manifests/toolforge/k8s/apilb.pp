class profile::toolforge::k8s::apilb (
        $servers = hiera('profile::toolforge::k8s::api_servers'),
    ) {

    class { 'haproxy':
        template => 'profile/toolforge/k8s/apilb/haproxy.cfg.erb',
    }

    nrpe::monitor_service { 'haproxy_failover':
        description  => 'haproxy failover',
        nrpe_command => '/usr/lib/nagios/plugins/check_haproxy --check=failover',
        notes_url    => 'https://phabricator.wikimedia.org/tag/toolforge/',
    }
}
