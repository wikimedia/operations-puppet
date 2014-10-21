# == Class: motd
#
# Module for customizing MOTD (Message of the Day) banners.
#
class motd {
    file { '/etc/update-motd.d':
        ensure  => directory,
        recurse => true,
        ignore  => '9*',
        purge   => true,
        notify  => Exec['update_motd'],
    }

    exec { 'update_motd':
        command     => '/bin/run-parts --lsbsysinit /etc/update-motd.d > /run/motd',
        refreshonly => true,
    }
}
