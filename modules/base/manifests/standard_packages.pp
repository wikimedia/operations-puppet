class base::standard_packages {

    if os_version('ubuntu >= trusty') {
        package { [ "linux-tools-${::kernelrelease}", 'linux-tools-generic' ]:
            ensure => present,
        }
    }

    package { [ 'command-not-found', 'command-not-found-data' ]:
        ensure => absent,
    }

    $packages = [
        'acct',
        'ack-grep',
        'atop',
        'coreutils',
        'debian-goodies',
        'dstat',
        'ethtool',
        'gdisk',
        'htop',
        'httpry',
        'iperf',
        'jq',
        'lldpd',
        'molly-guard',
        'ncdu',
        'ngrep',
        'pigz',
        'pv',
        'pxz',
        'screen',
        'strace',
        'sysstat',
        'tcpdump',
        'tmux',
        'tree',
        'tshark',
        'tzdata',
        'vim',
        'wipe',
        'xfsprogs',
        'zsh-beta',
    ]

    package { $packages:
        ensure => latest,
    }

    require_package('gdb', 'apt-transport-https')
    require_package('git')

    # This should be in $packages, but moved here temporarily because it's
    # currently broken on jessie hosts...
    if ! os_version('debian >= jessie') {
        package { 'quickstack': ensure => latest }
    }

    if $::network_zone == 'internal' {
        include nrpe
    }

    # uninstall these packages
    package { [
            'apport',
            'apt-listchanges',
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
