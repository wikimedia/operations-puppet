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
        system => true,
    }

    user { 'kubeproxy':
        ensure => present,
        gid    => 'kubeproxy',
        shell  => '/bin/false',
        home   => '/nonexistent',
        system => true,
    }

    # Trusty's python-requests package is buggy
    # and would break watching kubernetes for changes
    package { 'requests':
        provider => 'pip',
        ensure   => latest,
        require  => Package['python-requests'],
    }

    include k8s::ssl

    # Temporarily not run on non-active proxies
    # note that having redis based replication
    # instead of having processes syncing every proxy
    # with kubernetes is a bad idea, we're doing it just
    # because that's how OGE integration worked.
    $should_run = ($::hostname != $active_proxy)
    base::service_unit{ 'kubesync':
        ensure    => $should_run,
        refresh   => true,
        systemd   => true,
        upstart   => true,
        subscribe => [File['/usr/local/sbin/kube2proxy'],File['/var/lib/kubernetes/ssl/certs/ca.pem']],
    }

}
