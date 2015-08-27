# == Class: exim4
#
# This class installs & manages Exim4 for Debian, http://exim.org/
#
# == Parameters
#
# [*config*]
#   A template for exim4.conf. Required.
#
# [*filter*]
#   A template for system_filter. Optional.
#
# [*variant*]
#   The Debian package variant. "light" or "heavy"
#
# [*queuerunner*]
#   The queue runner config option.

class exim4(
  $config,
  $variant = 'light',
  $queuerunner = 'combined',
  $filter=undef,
) {
    validate_re($variant, '^(light|heavy)$')
    validate_re($queuerunner, '^(combined|no|separate|ppp|nodaemon|queueonly)$')

    package { [
        'exim4-config',
        "exim4-daemon-${variant}",
        ]:
        ensure => installed,
    }

    $servicestatus = $queuerunner ? {
        'queueonly' => false,
        default     => true,
    }

    service { 'exim4':
        ensure    => running,
        hasstatus => $servicestatus,
        require   => Package["exim4-daemon-${variant}"],
    }

    # mount tmpfs over the scan & db directories, for efficiency
    if $variant == 'heavy' {
        # allow o+x for /var/spool/exim4 so that subdirs below can be accessed
        file { '/var/spool/exim4':
            ensure  => directory,
            owner   => 'Debian-exim',
            group   => 'Debian-exim',
            mode    => '0751',
            require => Package["exim4-daemon-${variant}"],
        }

        # catch-22 with Puppet + mkdir/mount/chmod. The Debian package doesn't
        # ship $spool/scan, but exim4/exiscan mkdirs it on demand
        exec { 'mkdir /var/spool/exim4/scan':
            path    => '/bin:/usr/bin',
            creates => '/var/spool/exim4/scan',
            require => Package["exim4-daemon-${variant}"],
        }

        mount { [ '/var/spool/exim4/scan', '/var/spool/exim4/db' ]:
            ensure  => mounted,
            device  => 'none',
            fstype  => 'tmpfs',
            options => 'defaults',
            atboot  => true,
            require => Exec['mkdir /var/spool/exim4/scan'],
            before  => Service['exim4'],
        }

        file { [ '/var/spool/exim4/scan', '/var/spool/exim4/db' ]:
            ensure  => directory,
            owner   => 'Debian-exim',
            group   => 'Debian-exim',
            mode    => '1777',
            require => Mount['/var/spool/exim4/scan', '/var/spool/exim4/db'],
            before  => Service['exim4'],
        }
    }

    # shortcuts update-exim4.conf from messing with us
    # and stops debconf prompts about it from showing up
    file { '/etc/exim4/update-exim4.conf.conf':
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        content => "dc_eximconfig_configtype=none\n",
        require => Package['exim4-config'],
    }

    file { '/etc/default/exim4':
        ensure  => present,
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        content => template('exim4/exim4.default.erb'),
        require => Package['exim4-config'],
    }

    file { '/etc/exim4/aliases':
        ensure  => directory,
        owner   => 'root',
        group   => 'Debian-exim',
        mode    => '0755',
        require => Package['exim4-config'],
    }

    file { '/etc/exim4/dkim':
        ensure  => directory,
        purge   => true,
        owner   => 'root',
        group   => 'Debian-exim',
        mode    => '0750',
        require => Package['exim4-config'],
    }

    $filter_ensure = $filter ? {
        undef   => absent,
        default => present,
    }

    file { '/etc/exim4/system_filter':
        ensure  => $filter_ensure,
        owner   => 'root',
        group   => 'Debian-exim',
        mode    => '0444',
        content => $filter,
        require => Package['exim4-config'],
    }

    file { '/etc/exim4/exim4.conf':
        ensure  => present,
        owner   => 'root',
        group   => 'Debian-exim',
        mode    => '0440',
        content => $config,
        require => Package['exim4-config'],
        notify  => Service['exim4'],
    }
}
