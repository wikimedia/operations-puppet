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
        'gdb',
        'gdisk',
        'git',
        'htop',
        'httpry',
        'iperf',
        'jq',
        'libtemplate-perl', # Suggested by vim-scripts
        'lldpd',
        'lshw',
        'molly-guard',
        'moreutils',
        'numactl',
        'ncdu',
        'ngrep',
        'pv',
        'psmisc',
        'quickstack',
        'screen',
        'strace',
        'sysstat',
        'tcpdump',
        'tmux',
        'tree',
        'tshark',
        'vim',
        'vim-addon-manager',
        'vim-scripts',
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

    # Trusty doesn't provide the emacs meta packages, which pull in the latest version
    if os_version('ubuntu >= trusty') {
        require_package('emacs24-nox')
    } else {
        require_package('emacs-nox')
    }

    # Installed by default on Ubuntu, but not used (and it's setuid root, so
    # a potential security risk).
    #
    # Limited to Ubuntu, since Debian doesn't pull it in by default
    if os_version('ubuntu >= trusty') {
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
    if $facts['is_virtual'] == false and $::processor0 !~ /AMD/ {
        require_package('mcelog')
    }

    # Pulled in via tshark above, defaults to "no"
    debconf::seen { 'wireshark-common/install-setuid':
        require => Package['tshark'],
    }

    # An upgrade from jessie to stretch leaves some old binary
    # packages around, remove those
    if os_version('debian == stretch') {
        package { [
                  'libdns-export100',
                  'libirs-export91',
                  'libisc-export95',
                  'libisccfg-export90',
                  'liblwres90',
                  'libgnutls-deb0-28',
                  'libhogweed2',
                  'libjasper1',
                  'libnettle4',
                  'libruby2.1',
                  'ruby2.1'
            ]:
            ensure => absent,
        }
    }
}
