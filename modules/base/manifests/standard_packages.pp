class base::standard_packages {

    if os_version('ubuntu >= trusty') {
        package { [ "linux-tools-${::kernelrelease}", 'linux-tools-generic' ]:
            ensure => present,
        }
    }

    package { [ 'command-not-found', 'command-not-found-data' ]:
        ensure => absent,
    }

    require_package('acct', 'ack-grep', 'atop', 'debian-goodies', 'dstat', 'ethtool')
    require_package('gdisk', 'htop', 'httpry', 'iperf', 'jq', 'lldpd', 'molly-guard')
    require_package('moreutils', 'ncdu', 'ngrep', 'pv', 'screen', 'strace', 'sysstat')
    require_package('tcpdump', 'tmux', 'tree', 'tshark', 'vim', 'wipe', 'xfsprogs', 'zsh-beta')

    package { 'tzdata': ensure => latest }

    require_package('gdb', 'apt-transport-https')
    require_package('git')

    # for hardware monitoring via IPMI (T125205)
    if os_version('debian >= jessie') {
        require_package('freeipmi', 'libipc-run-perl')
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
