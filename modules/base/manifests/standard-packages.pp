# == Class: base::standard-packages
#
# Sets up standard packages that might be useful on all hosts.
#
# === Parameters
#
# [*atop_keeplogs_days*]
#   Number of days to keep atop logs for.
#
class base::standard-packages(
    $atop_logrotate_days = 7,
){

    if ubuntu_version('>= trusty') {
        package { [ "linux-tools-${::kernelrelease}", 'linux-tools-generic' ]:
            ensure => present,
        }

        package { 'quickstack':
            ensure => present,
        }
    }

    $packages = [
        'wipe',
        'tzdata',
        'zsh-beta',
        'xfsprogs',
        'screen',
        'gdb',
        'iperf',
        'atop',
        'htop',
        'vim',
        'sysstat',
        'ngrep',
        'httpry',
        'acct',
        'git-core',
        'ack-grep',
        'tree',
        'debian-goodies',
        'ethtool',
    ]

    if $::lsbdistid == 'Ubuntu' {
        package { $packages:
            ensure => latest,
        }

        if $::network_zone == 'internal' {
            include nrpe
        }

        # Run lldpd on all >= Lucid hosts
        if $::lsbdistid == 'Ubuntu' and versioncmp($::lsbdistrelease, '10.04') >= 0 {
            package { 'lldpd':
                ensure => latest, }
        }

        # DEINSTALL these packages
        package { [ 'mlocate', 'os-prober' ]:
            ensure => absent,
        }

        file { '/etc/logrotate.d/atop':
            require => Package['atop'],
            content => template('base/atop.logrotate.erb'),
        }
    }
}
