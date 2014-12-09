class base::standard-packages {

    if os_version('ubuntu >= trusty') {
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
    }
}
