# == Class: motd
#
# Module for customizing MOTD (Message of the Day) banners.
#
class motd {
    # For Ubuntu trusty+, pam_motd is configured by sshd's pam
    # configuration to read from /run directly and hence has no need
    # for this.
    #
    # For Debian jessie (as of 2014-12-31) the situation is quite complicated:
    # https://lists.debian.org/debian-devel/2014/12/msg00368.html
    if os_version('debian <= jessie || ubuntu <= precise') {
        file { '/etc/motd':
            ensure => link,
            target => '/var/run/motd',
            force  => true,
        }
    } elsif $::realm == 'labs' and os_version('ubuntu == trusty') {
        # In Labs the pam configuration is overwritten, effectively
        # disabling motds on Trusty instances.  Thus we create it
        # there as a workaround for T85910.
        file { '/etc/motd':
            ensure => link,
            target => '/run/motd.dynamic',
            force  => true,
        }
    } else {
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
