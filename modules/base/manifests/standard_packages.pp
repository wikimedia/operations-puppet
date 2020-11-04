class base::standard_packages {

    require_package ([
        'acct',
        'apt-transport-https',
        'byobu',
        'colordiff',
        'curl',
        'debian-goodies',
        'dnsutils',
        'dstat',
        'ethtool',
        'gdb',
        'gdisk',
        'git-fat',
        'git',
        'htop',
        'httpry',
        'iotop',
        'iperf',
        'jq',
        'libtemplate-perl', # Suggested by vim-scripts
        'lldpd',
        'lshw',
        'molly-guard',
        'moreutils',
        'net-tools',
        'numactl',
        'ncdu',
        'ngrep',
        'pigz',
        'psmisc',
        'pv',
        'python3',
        'quickstack',
        'screen',
        'strace',
        'sysstat',
        'tcpdump',
        'tmux',
        'tree',
        'vim',
        'vim-addon-manager',
        'vim-scripts',
        'wipe',
        'xfsprogs',
        'zsh',
    ])

    # These packages exists only from stretch onwards, once we are free of
    # jessie, remove the if and move them to the array above
    if os_version('debian > jessie') {
        require_package('icdiff')
        require_package('linux-perf')
    }

    package { 'tzdata': ensure => latest }

    # pxz was removed in buster. In xz >= 5.2 (so stretch and later), xz has
    # builtin threading support using the -T option, so pxz was removed
    if os_version('debian <= stretch') {
        require_package('pxz')
    }

    # ack-grep was renamed to ack
    if os_version('debian >= stretch') {
        require_package('ack')
    } else {
        require_package('ack-grep')
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

    # purge these packages
    package { [
            'atop', # atop causes severe performance degradation T192551 debian:896767
        ]:
        ensure => purged,
    }

    # real-hardware specific
    if $facts['is_virtual'] == false {
        # As of September 2015, mcelog still does not support newer AMD processors.
        # See <https://www.mcelog.org/faq.html#18>.
        if $::processor0 !~ /AMD/ {
            if os_version('debian <= stretch') {
                if versioncmp($::kernelversion, '4.12') < 0 {
                    $mcelog_ensure = 'present'
                } else {
                    $mcelog_ensure = 'absent'
                }
                package { 'mcelog':
                    ensure => $mcelog_ensure,
                }
                base::service_auto_restart { 'mcelog':
                    ensure => $mcelog_ensure,
                }
            }
            require_package('intel-microcode')
        }
        # rasdaemon replaces mcelog on buster
        if os_version('debian == buster') {
            require_package('rasdaemon')
            base::service_auto_restart { 'rasdaemon': }
        }
    }

    # for HP servers only - install the backplane health service and CLI
    # As of February 2018, we are using a version of Facter where manufacturer
    # is a current fact.  In a future upgrade, it will be a legacy fact and
    # should be replaced with a parse of the dmi fact (which will be a map not
    # a string).
    if $facts['is_virtual'] == false and $facts['manufacturer'] == 'HP' {
        require_package('hp-health')
    }

    # Pulled in via tshark below, defaults to "no"
    debconf::seen { 'wireshark-common/install-setuid': }
    package { 'tshark': ensure => present }

    # An upgrade from jessie to stretch leaves some old binary
    # packages around, remove those
    if os_version('debian == stretch') {
        package { [
                  'libapt-inst1.5',
                  'libapt-pkg4.12',
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
                  'ruby2.1',
                  'libpsl0',
                  'libwiretap4',
                  'libwsutil4',
                  'libbind9-90',
                  'libdns100',
                  'libisc95',
                  'libisccc90',
                  'libisccfg90',
                  'python-reportbug',
                  'libpng12-0'
            ]:
            ensure => absent,
        }
    }

    # An upgrade from stretch to buster leaves some old binary packages around, remove those
    if os_version('debian == buster') {
        package {['libbind9-140', 'libdns162', 'libevent-2.0-5', 'libisc160',
                  'libisccc140', 'libisccfg140', 'liblwres141', 'libonig4',
                  'libdns-export162', 'libhunspell-1.4-0', 'libisc-export160',
                  'libgdbm3', 'libyaml-cpp0.5v5',
                  'libperl5.24', 'ruby2.3', 'libruby2.3', 'libunbound2', 'git-core']:
            ensure => absent,
        }

        # mcelog is broken with the Linux kernel used in buster
        package {['mcelog']:
            ensure => purged,
        }
    }

    base::service_auto_restart { 'lldpd': }
    base::service_auto_restart { 'cron': }

    # Safe restarts are supported since systemd 219:
    # * systemd now provides a way to store file descriptors
    # per-service in PID 1. This is useful for daemons to ensure
    # that fds they require are not lost during a daemon
    # restart. The fds are passed to the daemon on the next
    # invocation in the same way socket activation fds are
    # passed. This is now used by journald to ensure that the
    # various sockets connected to all the system's stdout/stderr
    # are not lost when journald is restarted.
    if os_version('debian >= stretch') {
        base::service_auto_restart { 'systemd-journald': }
    }
}
