class base::standard-packages {

    # Which metapackage to install for `perf`.
    if ubuntu_version('>= trusty') {
        $linux_tools_package = 'linux-tools-generic'
    } else {
        $linux_tools_package = 'linux-tools'
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
        $linux_tools_package,
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
