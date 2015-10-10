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

    $users = hiera('k8s_users')
    # Ugly hack, ugh!
    $client_token = inline_template("<%= @users.select { |u| u['name'] == 'client-infrastructure' }[0]['token'] %>")

    $config = {
        'redis'       => 'localhost:6379',
        'kubernetes'  => {
            'master'  => "https://${master_host}:6443",
            'ca_cert' => '/var/lib/kubernetes/ssl/ca.pem',
            'token'   => $client_token,
        }
    }

    file { '/etc/kube2proxy.yaml':
        content => ordered_yaml($config),
        owner   => 'kubernetes',
        group   => 'kubernetes',
        mode    => '0440',
    }

    base::service_unit{ 'kube2proxy':
        ensure         => $ensure,
        refresh        => true,
        systemd        => true,
        service_params => $service_params,
        subscribe      => File[
            '/usr/local/sbin/kube2proxy',
            '/etc/kube2proxy.yaml'
        ],
    }

}
