class toollabs::kube2proxy(
    $master_host,
    $kube_token='test',
) {
    include k8s::users
    include k8s::ssl

    file { '/usr/local/sbin/kube2proxy':
        ensure => present,
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
        source => 'puppet:///modules/toollabs/kube2dynproxy.py',
    }

    require_package(['python3-requests', 'python3-redis', 'python3-yaml'])

    # Temporarily not run on non-active proxies
    # note that having redis based replication
    # instead of having processes syncing every proxy
    # with kubernetes is a bad idea, we're doing it just
    # because that's how OGE integration worked.
    if ensure_service($ensure) == 'running' {
        $should_run = hiera('active_proxy_host') ?{
            $::hostname => 'running',
            default     => 'stopped'
        }
        $service_params = {'ensure' => $should_run}
    } else {
        $service_params = {}
    }

    base::service_unit{ 'kube2proxy':
        ensure         => $ensure,
        refresh        => true,
        systemd        => true,
        service_params => $service_params,
        subscribe => [
                      File['/usr/local/sbin/kube2proxy'],
                      ],
    }

}
