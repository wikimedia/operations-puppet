# == Class: motd
#
# Module for customizing MOTD (Message of the Day) banners.
#
class motd {
    # This was incomplete & buggy in jessie, as detailed in
    # https://lists.debian.org/debian-devel/2014/12/msg00368.html
    #
    # This has been fixed since in stretch onwards.
    if os_version('debian jessie') {
        file { '/etc/motd':
            ensure => link,
            target => '/var/run/motd',
            force  => true,
        }
    } else {
        # Kill Debian's default copyright/warranty banner
        file { '/etc/motd':
            ensure => absent,
        }
    }

    file { '/etc/update-motd.d':
        ensure  => directory,
        owner   => 'root',
        group   => 'root',
        mode    => '0755',
        recurse => true,
        purge   => true,
    }

    include motd::defaults
}
