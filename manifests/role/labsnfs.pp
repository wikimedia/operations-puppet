
class role::labs::nfs::dumps {

    include standard

    package { 'nfs-kernel-server':
        ensure => present,
    }

    file { '/etc/exports':
        ensure  => present,
        source => 'puppet:///files/nfs/exports.dumps',
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
    }

}
