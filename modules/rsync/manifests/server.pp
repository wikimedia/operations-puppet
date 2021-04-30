# @summery The rsync server. Supports both standard rsync as well as rsync over ssh
#
# @param address the address to listen on can pass an empty string to have it listen on ipv4 and ipv6
# @param timeout the timeout in seconds
# @param use_chroot if yes funr rsync in chroot
# @param rsync_opts An array of rsync options
# @param rsyncd_conf a hash of additional rsync configuration options
# @param wrap_with_stunnel if true rsync will be wrapped in an ssltunnle
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
    Boolean                    $wrap_with_stunnel = false,
    Stdlib::Ensure::Service    $ensure_service    = 'running',
    Optional[Stdlib::Unixpath] $log_file          = undef,
) {
    ensure_packages(['rsync'])

    $rsync_fragments = '/etc/rsync.d'
    $rsync_conf      = '/etc/rsyncd.conf'
    $rsync_pid       = '/var/run/rsync.pid'

    # rsync daemon defaults file
    file { '/etc/default/rsync':
        ensure  => present,
        mode    => '0444',
        owner   => 'root',
        group   => 'root',
        content => template('rsync/rsync.default.erb'),
    }

    if $wrap_with_stunnel {
        ensure_packages(['stunnel4'])
        file { '/etc/stunnel/rsync.conf':
            ensure  => present,
            mode    => '0444',
            owner   => 'root',
            group   => 'root',
            content => template('rsync/stunnel.conf.erb'),
        }
        file_line { 'enable_stunnel':
            ensure   => present,
            path     => '/etc/default/stunnel4',
            line     => 'ENABLED=1  # Managed by puppet',
            match    => '^ENABLED=',
            multiple => false,
        }
        service { 'stunnel4':
            ensure    => $ensure_service,
            enable    => true,
            subscribe => [
                Exec['compile fragments'],
                File['/etc/default/rsync', '/etc/stunnel/rsync.conf'],
                File_line['enable_stunnel'],
                Package['stunnel4'],
            ],
        }
    }

    # TODO: When we have migrated all rsync usage off of cleartext and to use $wrap_with_stunnel,
    # we can ensure => stopped this.  https://phabricator.wikimedia.org/T237424
    service { 'rsync':
        ensure    => $ensure_service,
        enable    => true,
        subscribe => [Exec['compile fragments'], File['/etc/default/rsync']],
    }

    file { $rsync_fragments:
        ensure  => directory,
        recurse => true,
        purge   => true,
    }

    file { "${rsync_fragments}/header":
        content => template('rsync/header.erb'),
    }

    # perhaps this should be a script
    # this allows you to only have a header and no fragments, which happens
    # by default if you have an rsync::server but not an rsync::repo on a host
    # which happens with cobbler systems by default
    $command = @("COMMAND"/L)
    ls ${rsync_fragments}/frag-* 1>/dev/null 2>/dev/null && \
    if [ $? -eq 0 ]; then cat ${rsync_fragments}/header ${rsync_fragments}/frag-* > ${rsync_conf}; \
    else cat ${rsync_fragments}/header > ${rsync_conf}; fi; $(exit 0) \
    | COMMAND
    exec { 'compile fragments':
        refreshonly => true,
        command     => $command,
        subscribe   => File["${rsync_fragments}/header"],
        path        => '/bin:/usr/bin',
    }
}
