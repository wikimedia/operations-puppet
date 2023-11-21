# @summary The rsync server. Supports both standard rsync as well as rsync over ssh
#
# @param address the address to listen on can pass an empty string to have it listen on ipv4 and ipv6
# @param timeout the timeout in seconds
# @param use_chroot if yes funr rsync in chroot
# @param rsync_opts An array of rsync options
# @param rsyncd_conf a hash of additional rsync configuration options
# @param ensure_service the ensure state of the service
# @param log_file path to the log file to use
class rsync::server(
    Variant[
        Stdlib::IP::Address,
        Enum['']
    ]                          $address           = '0.0.0.0',
    Integer                    $timeout           = 300,
    Stdlib::Yes_no             $use_chroot        = 'yes',
    Array                      $rsync_opts        = [],
    Hash                       $rsyncd_conf       = {},
    Stdlib::Ensure::Service    $ensure_service    = 'running',
    Optional[Stdlib::Unixpath] $log_file          = undef,
) {
    ensure_packages(['rsync'])

    $rsync_conf      = '/etc/rsyncd.conf'
    $rsync_pid       = '/var/run/rsync.pid'

    concat { $rsync_conf:
        ensure => present,
        owner  => 'root',
        group  => 'root',
        mode   => '0444',
    }

    # rsync daemon defaults file
    file { '/etc/default/rsync':
        ensure  => present,
        mode    => '0444',
        owner   => 'root',
        group   => 'root',
        content => template('rsync/rsync.default.erb'),
    }

    # TODO: When we have migrated all rsync usage off of cleartext and to use stunnel,
    # we can ensure => stopped this.  https://phabricator.wikimedia.org/T237424
    service { 'rsync':
        ensure    => $ensure_service,
        enable    => true,
        require   => Package['rsync'],
        subscribe => [Concat[$rsync_conf], File['/etc/default/rsync']],
    }

    # Cleanup the old method of concatenating the config
    file { '/etc/rsync.d':
        ensure  => absent,
        recurse => true,
        purge   => true,
        force   => true,
    }

    concat::fragment { "${rsync_conf}-header":
        target  => $rsync_conf,
        order   => '01',
        content => template('rsync/header.erb'),
    }
}
