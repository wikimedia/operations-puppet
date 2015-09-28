class toollabs::kube2proxy(
    $ensure='present',
    $ssldir='/var/lib/puppet/ssl/',
    $kubemaster='https://tools-k8s-master-01.tools.eqiad.wmflabs:6443',
    $kube_token='test')
{

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

    file { '/var/lib/kube2proxy':
        ensure => ensure_directory($ensure),
        owner  => 'kubeproxy',
        group  => 'kubeproxy',
        mode   => '0755',
    }

    file { '/var/lib/kube2proxy/ca.pem':
        owner  => 'kubeproxy',
        group  => 'kubeproxy',
        mode   => '0444',
        source => "${ssldir}/certs/ca.pem",
    }

    base::service_unit{ 'kubesync':
        ensure    => $ensure,
        refresh   => true,
        systemd   => true,
        upstart   => true,
        subscribe => [File['/usr/local/sbin/kube2proxy'],File['/var/lib/kube2proxy/ca.pem']],
    }

}
