class toollabs::kube2proxy(
    $ensure='present',
    $ssldir='/var/lib/puppet/ssl/',
    $kubemaster='https://tools-k8s-master-01.tools.eqiad.wmflabs:6443',
    $kube_token='test',
    ){

    file { '/usr/local/sbin/kube2proxy':
        ensure => $ensure,
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
        source => 'puppet:///modules/toollabs/kube2dynproxy.py',
    }

    group { 'kubeproxy':
        ensure => present,
        system => true,
    }

    user { 'kubeproxy':
        ensure  => present,
        gid     => 'kubeproxy',
        shell   => '/bin/false',
        home    => '/nonexistent',
        system  => true,
        require => Group['kubeproxy']
    }

    require_package(['python-requests', 'python-redis', 'python-yaml'])

    # Trusty and jessie's python-requests package is buggy
    # and would break watching kubernetes for changes
    package { 'requests':
        provider => 'pip',
        ensure   => latest,
    }

    include k8s::ssl

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
        $params = {'ensure' => $should_run}
    } else {
        $params = {}
    }

    base::service_unit{ 'kube2proxy':
        ensure         => $ensure,
        refresh        => true,
        systemd        => true,
        upstart        => true,
        service_params => $params,
        subscribe => [
                      File['/usr/local/sbin/kube2proxy'],
                      File['/var/lib/kubernetes/ssl/certs/ca.pem']
                      ],
    }

}
