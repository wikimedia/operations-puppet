# == Class dsh
#
# Standard installation of dsh (Dancer's distributed shell)
#
# Also sets up all groups from modules/dsh/files/group
class dsh {
    package { 'dsh':
        ensure => present,
    }

    include dsh::config
}

# == Class dsh::config
#
# Sets up dsh config files alone, without actually
# setting up dsh. Useful primarily for monitoring
class dsh::config {
    file { '/etc/dsh':
        ensure => directory,
        owner  => 'root',
        group  => 'root',
        mode   => '0444',
    }
    file { '/etc/dsh/group':
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        source  => 'puppet:///modules/dsh/group',
        recurse => true,
    }
    file { '/etc/dsh/dsh.conf':
        owner  => 'root',
        group  => 'root',
        mode   => '0444',
        source => 'puppet:///modules/dsh/dsh.conf',
    }
}
