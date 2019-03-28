# Set up a kube2proxy service.

class toollabs::kube2proxy(
    $master_host,
    $kube_token='test',
) {
    if os_version('debian == jessie') {
        apt::repository{ 'component/kube2proxy':
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
        source => 'puppet:///modules/toollabs/kube2proxy.py',
    }

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

    $users = hiera('k8s_infrastructure_users')
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

    base::service_unit{ 'kube2proxy':
        ensure         => present,
        refresh        => true,
        systemd        => systemd_template('kube2proxy'),
        service_params => $service_params,
        subscribe      => File[
            '/usr/local/sbin/kube2proxy',
            '/etc/kube2proxy.yaml'
        ],
    }
}
