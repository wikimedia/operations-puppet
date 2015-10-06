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

    $packages = [
      'python3-pip',
      'python3-redis',
      'python3-yaml',
      'python3-requests',]

    require_package($packages)

    # Temporarily not run on non-active proxies
    # note that having redis based replication
    # instead of having processes syncing every proxy
    # with kubernetes is a bad idea, we're doing it just
    # because that's how OGE integration worked.
    $should_run = hiera('active_proxy_host') ?{
        $::hostname => 'running',
        default     => 'stopped'
    }
    $service_params = {'ensure' => $should_run}

    base::service_unit{ 'kube2proxy':
        ensure         => $ensure,
        refresh        => true,
        systemd        => true,
        service_params => $service_params,
        subscribe      => [
                      File['/usr/local/sbin/kube2proxy'],
                      ],
    }

}
