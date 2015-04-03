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

    # Can clash with java::tools class
    if ! defined ( Package['gdb'] ) {
        package { 'gdb':
            ensure => latest
        }
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
    unless $::is_virtual {
        package { 'mcelog': ensure => latest }
        package { 'intel-microcode': ensure => latest }
    }
}
