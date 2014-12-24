class base::standard-packages {

    if os_version('ubuntu >= trusty') {
        package { [ "linux-tools-${::kernelrelease}", 'linux-tools-generic' ]:
            ensure => present,
        }

    }

    $packages = [
        'coreutils',
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
        'lldpd',
        'quickstack',
        'pv',
        'mcelog',
        'intel-microcode',
    ]

    package { $packages:
        ensure => latest,
    }

    if $::network_zone == 'internal' {
        include nrpe
    }

    # uninstall these packages
    package { [ 'mlocate', 'os-prober' ]:
        ensure => absent,
    }
}
