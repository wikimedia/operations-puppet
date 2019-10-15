class toolforge::kube2proxy (
    $k8s_infrastructure_users, # complex datatype?
    Stdlib::Fqdn $master_host,
    String       $active_proxy_host,
    String       $kube_token='test',
) {
    if os_version ('debian == jessie') {
        apt::repository { 'component-kube2proxy':
            uri        => 'http://apt.wikimedia.org/wikimedia',
            dist       => 'jessie-wikimedia',
            components => 'component/kube2proxy',
            source     => false,
        }
    }

    $packages = [
      'python3-pip',
      'python3-redis',
      'python3-yaml',
      'python3-requests',]

    require_package($packages)

    file { '/usr/local/sbin/kube2proxy':
        ensure => present,
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
        source => 'puppet:///modules/toolforge/kube2proxy.py',
    }

    # Temporarily not run on non-active proxies
    # note that having redis based replication
    # instead of having processes syncing every proxy
    # with kubernetes is a bad idea, we're doing it just
    # because that's how OGE integration worked.
    $should_run = $active_proxy_host ?{
        $::hostname => 'running',
        default     => 'stopped'
    }

    $service_params = {'ensure' => $should_run}

    $users = $k8s_infrastructure_users
    $client_token = $users['proxy-infrastructure']['token']

    $config = {
        'redis'       => 'localhost:6379',
        'kubernetes'  => {
            'master'  => "https://${master_host}:6443",
            'token'   => $client_token,
        },
    }

    file { '/etc/kube2proxy.yaml':
        content => ordered_yaml($config),
        owner   => 'kube',
        group   => 'kube',
        mode    => '0440',
    }

    systemd::service { 'kube2proxy':
        ensure         => present,
        restart        => true,
        content        => systemd_template('kube2proxy'),
        service_params => $service_params,
        subscribe      => File[
            '/usr/local/sbin/kube2proxy',
            '/etc/kube2proxy.yaml'
        ],
    }
}
