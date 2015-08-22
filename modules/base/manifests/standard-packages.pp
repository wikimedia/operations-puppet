class base::standard-packages {

    if os_version('ubuntu >= trusty') {
        package { [ "linux-tools-${::kernelrelease}", 'linux-tools-generic' ]:
            ensure => present,
        }

    }

    $packages = [
        'acct',
        'ack-grep',
        'atop',
        'coreutils',
        'debian-goodies',
        'ethtool',
        'htop',
        'httpry',
        'iperf',
        'lldpd',
        'molly-guard',
        'ngrep',
        'pv',
        'screen',
        'strace',
        'sysstat',
        'tcpdump',
        'tree',
        'tzdata',
        'vim',
        'wipe',
        'xfsprogs',
        'zsh-beta',
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

    # Can clash with authdns::scripts class
    if ! defined(Package['git-core']){
        package { 'git-core':
            ensure => latest,
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
    # Note: False is quoted on purpose
    # lint:ignore:quoted_booleans
    if $::is_virtual == 'false' {
    # lint:endignore
        package { 'mcelog': ensure => present }
    }
}
