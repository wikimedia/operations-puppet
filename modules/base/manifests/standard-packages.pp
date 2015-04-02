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
        'pv',
        'tcpdump',
    ]

    package { $packages:
        ensure => latest,
    }

    # This should be in $packages, but moved here temporarily because it's
    # currently broken on jessie hosts...
    if ! os_version('debian >= jessie') {
        package { 'quickstack': ensure => latest }
    }

    if $::network_zone == 'internal' {
        include nrpe
    }

    # uninstall these packages
    package { [ 'mlocate', 'os-prober' ]:
        ensure => absent,
    }

    # real-hardware specific
    if $::is_virtual == 'false' {
        package { 'mcelog': ensure => latest }
        package { 'intel-microcode': ensure => latest }
    }
}
