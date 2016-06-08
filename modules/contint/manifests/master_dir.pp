# Convenience class to avoid dependency hell.
#
# Creates a directory used on the contint master
class contint::master_dir() {
    # The name is not smart, but please forgive me for now...
    file { '/srv/ssd':
        ensure => 'directory',
        owner  => 'root',
        group  => 'root',
    }

    if $::hostname == 'gallium' {
        # gallium received a SSD drive (T82401) mount it
        mount { '/srv/ssd':
            ensure  => mounted,
            device  => '/dev/sdb1',
            fstype  => 'xfs',
            options => 'noatime,nodiratime,nobarrier,logbufs=8',
            require => File['/srv/ssd'],
        }
    }
}
