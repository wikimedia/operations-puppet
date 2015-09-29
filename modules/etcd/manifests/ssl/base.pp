class etcd::ssl::base ($ssldir = '/var/lib/puppet/ssl') {
    $basedir = '/var/lib/etcd/ssl'
    $pubdir = "${basedir}/certs"
    $cacert = "${pubdir}/ca.pem"

    # If $basedir is /var/lib/etcd/ssl,
    # and this class is being used without
    # the etcd package being installed, then
    # we need this directory created.
    # Not sure what is best to do, please patch away.
    $vardir = '/var/lib/etcd'

    file { [$vardir, $basedir, $pubdir]:
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
