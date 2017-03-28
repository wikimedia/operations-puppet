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
        'zsh',
    ])

    package { 'tzdata': ensure => latest }

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

    if os_version('ubuntu >= precise') {
        package { 'ntfs-3g': ensure => absent }
    }

    # On Ubuntu, eject is installed via the ubuntu-minimal package
    # Uninstall in on Debian since it ships a setuid helper and we don't
    # have servers with installed optical drives
    if os_version('debian >= jessie') {
        package { 'eject': ensure => absent }
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
