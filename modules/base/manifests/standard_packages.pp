class base::standard_packages {

    if os_version('ubuntu >= trusty') {
        package { [ "linux-tools-${::kernelrelease}", 'linux-tools-generic' ]:
            ensure => present,
        }
    }

    require_package ([
        'acct',
        'ack-grep',
        'apt-transport-https',
        'atop',
        'debian-goodies',
        'dstat',
        'ethtool',
        'gdisk',
        'gdb',
        'git',
        'htop',
        'httpry',
        'iperf',
        'jq',
        'lldpd',
        'lshw',
        'molly-guard',
        'moreutils',
        'ncdu',
        'ngrep',
        'quickstack',
        'pv',
        'screen',
        'strace',
        'sysstat',
        'tcpdump',
        'tmux',
        'tree',
        'tshark',
        'vim',
        'wipe',
        'xfsprogs',
        'zsh-beta',
    ])

    package { 'tzdata': ensure => latest }

    if $::network_zone == 'internal' {
        include nrpe
    }

    # uninstall these packages
    package { [
            'apport',
            'apt-listchanges',
            'command-not-found',
            'command-not-found-data',
            'ecryptfs-utils',
            'mlocate',
            'os-prober',
            'python3-apport',
            'wpasupplicant',
        ]:
        ensure => absent,
    }

    # real-hardware specific
    # As of September 2015, mcelog still does not support newer AMD processors.
    # See <http://www.mcelog.org/faq.html#18>.
    # Note: False is quoted on purpose
    # lint:ignore:quoted_booleans
    if $::is_virtual == 'false' and $::processor0 !~ /AMD/ {
    # lint:endignore
        require_package('mcelog')
    }
}
