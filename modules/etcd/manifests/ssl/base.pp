class etcd::ssl::base ($ssldir = '/var/lib/puppet/ssl') {
    $basedir = '/var/lib/etcd/ssl'
    $pubdir = "${basedir}/certs"
    $cacert = "${pubdir}/ca.pem"
    file { $basedir:
        ensure  => directory,
        owner   => 'etcd',
        group   => 'etcd',
        mode    => '0500',
        require => Package['etcd']
    }

    file { $pubdir:
        ensure  => directory,
        owner   => 'etcd',
        group   => 'etcd',
        mode    => '0500',
    }

    file { $cacert:
        ensure => present,
        owner  => 'etcd',
        group  => 'etcd',
        mode   => '0400',
        source => "${ssldir}/certs/ca.pem",
    }

}
