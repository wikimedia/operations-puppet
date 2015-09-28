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
        source => 'puppet:///modules/toollabs/kube2dynproxy.py'
    }

    # TODO: create the user locally if possible

    file { '/var/lib/kube2proxy':
        ensure => ensure_directory($ensure),
        owner  => 'root',
        group  => 'root',
        mode   => '0755'
    }

    file { '/var/lib/kube2proxy/ca.pem':
        owner  => 'root',
        group  => 'root',
        mode   => '0444',
        source => "${ssldir}/certs/ca.pem",
    }

    base::service_unit{ 'kubesync':
        ensure    => $ensure,
        refresh   => true,
        upstart   => true,
        subscribe => [File['/usr/local/sbin/kube2proxy'],File['/var/lib/kube2proxy/ca.pem']],
    }

}
