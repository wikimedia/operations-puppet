class etcd::ssl::base (
    $ssldir   = '/var/lib/puppet/ssl'
    $owner    = 'etcd',
    $group    = 'etcd',
    $dirmode  = '0500',
    $filemode = '0400',
) {
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
        owner   => $owner,
        group   => $group,
        mode    => $dirmode
    }

    file { $cacert:
        ensure => present,
        owner  => $owner,
        group  => $group,
        mode   => $filemode,
        source => "${ssldir}/certs/ca.pem",
    }

}
