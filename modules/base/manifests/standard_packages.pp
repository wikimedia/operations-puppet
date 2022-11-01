class base::standard_packages {

    ensure_packages ([
        'acct', 'byobu', 'colordiff', 'curl', 'debian-goodies', 'dnsutils', 'dstat',
        'ethtool', 'gdb', 'gdisk', 'git', 'htop', 'httpry', 'iotop', 'iperf', 'jq',
        'libtemplate-perl', 'lldpd', 'lshw', 'molly-guard', 'moreutils', 'net-tools', 'numactl', 'ncdu',
        'ngrep', 'pigz', 'psmisc', 'pv', 'python3', 'quickstack', 'screen', 'strace', 'sysstat', 'tcpdump',
        'tmux', 'tree', 'vim', 'vim-addon-manager', 'vim-scripts', 'wipe', 'xfsprogs', 'zsh',
        'icdiff', 'linux-perf', 'bsd-mailx', 'ack', 'netcat-openbsd',
    ])
    if debian::codename::lt('bullseye') {
        # bullseye has version 2.30 which uses version 2 by default
        git::systemconfig { 'protocol_v2':
            settings => {
                'protocol' => {
                    'version' => '2',
                }
            }
        }
    }
    package { 'tzdata': ensure => latest }

    # Pulled in via tshark below, defaults to "no"
    debconf::seen { 'wireshark-common/install-setuid': }
    package { 'tshark': ensure => present }

    # packages only available in buster and later
    if debian::codename::ge('buster') {
        ensure_packages(['python3-wmflib'])
    }

    # git-fat hasn't been ported to Python 3 yet, T279509
    if debian::codename::lt('bullseye') {
        ensure_packages('git-fat')
    }

    # pxz was removed in buster. In xz >= 5.2 (so stretch and later), xz has
    #      builtin threading support using the -T option, so pxz was removed
    # apt-transport-https is a transition package in Buster, apt has HTTPS support by default
    if debian::codename::lt('buster') {
        ensure_packages('pxz')
        ensure_packages('apt-transport-https')
    }

    # uninstall these packages
    package { [
        'apport', 'command-not-found', 'command-not-found-data',
        'ecryptfs-utils', 'mlocate', 'os-prober', 'python3-apport', 'wpasupplicant']:
            ensure => absent,
    }

    # purge these packages
    # atop causes severe performance degradation T192551 debian:896767
    package { [
            'atop', 'apt-listchanges',
        ]:
        ensure => purged,
    }

    # Python 2 is unsupported in Bullseye, but still included to build a few packages
    # (like Chromium and Pypy). Absent it to ensure that they get pruned on dist-upgrades
    # and to ensure that roles get fixed to strip Python 2 dependencies when moving to
    # Bullseye
    if debian::codename::eq('bullseye') {
        package { [
            'libpython2.7', 'libpython2.7-dev', 'libpython2.7-minimal', 'python2.7',
            'libpython2.7-stdlib', 'python2.7-dev', 'python2.7-minimal', 'python2.7-dbg',
            'python2.7-doc', 'python2.7-examples', 'libpython2.7-testsuite']:
                ensure => absent,
        }
    }

    # real-hardware specific
    unless $facts['is_virtual'] {
        # As of September 2015, mcelog still does not support newer AMD processors.
        # See <https://www.mcelog.org/faq.html#18>.
        if $::processor0 !~ /AMD/ {
            ensure_packages('intel-microcode')
            if debian::codename::le('stretch') {
                $mcelog_ensure = versioncmp($::kernelversion, '4.12') ? {
                    -1      => 'present',
                    default => 'absent',
                }
                package { 'mcelog':
                    ensure => $mcelog_ensure,
                }
                profile::auto_restarts::service { 'mcelog':
                    ensure => $mcelog_ensure,
                }
            }
        }
        # rasdaemon replaces mcelog on buster
        if debian::codename::eq('buster') {
            ensure_packages('rasdaemon')
            profile::auto_restarts::service { 'rasdaemon': }
        }

        # for HP servers only - install the backplane health service and CLI
        # As of February 2018, we are using a version of Facter where manufacturer
        # is a current fact.  In a future upgrade, it will be a legacy fact and
        # should be replaced with a parse of the dmi fact (which will be a map not
        # a string).
        if $facts['manufacturer'] == 'HP' {
            # this package doesn't seem to exists for debian bullseye, see T300438
            if debian::codename::lt('bullseye') {
                ensure_packages('hp-health')
            }
        }
    }

    case debian::codename() {
        'stretch': {
            # A dist upgrade to stretch leaves some old binary packages around, remove those
            $absent_packages = [
                'libapt-inst1.5', 'libapt-pkg4.12', 'libdns-export100', 'libirs-export91',
                'libisc-export95', 'libisccfg-export90', 'liblwres90', 'libgnutls-deb0-28',
                'libhogweed2', 'libjasper1', 'libnettle4', 'libruby2.1', 'ruby2.1', 'libpsl0',
                'libwiretap4', 'libwsutil4', 'libbind9-90', 'libdns100', 'libisc95', 'libisccc90',
                'libisccfg90', 'python-reportbug', 'libpng12-0'
            ]
            $purged_packages = []
        }
        'buster': {
            # A dist upgrade to buster leaves some old binary packages around, remove those
            $absent_packages = [
                'libbind9-140', 'libdns162', 'libevent-2.0-5', 'libisc160', 'libisccc140', 'libisccfg140',
                'liblwres141', 'libonig4', 'libdns-export162', 'libhunspell-1.4-0', 'libisc-export160',
                'libgdbm3', 'libyaml-cpp0.5v5', 'libperl5.24', 'ruby2.3', 'libruby2.3', 'libunbound2', 'git-core',
                'libboost-atomic1.62.0', 'libboost-chrono1.62.0', 'libboost-date-time1.62.0',
                'libboost-filesystem1.62.0', 'libboost-iostreams1.62.0', 'libboost-locale1.62.0',
                'libboost-log1.62.0', 'libboost-program-options1.62.0', 'libboost-regex1.62.0',
                'libboost-system1.62.0', 'libboost-thread1.62.0', 'libmpfr4', 'libprocps6', 'libunistring0',
                'libbabeltrace-ctf1', 'libleatherman-data', 'apt-transport-https'
            ]
            # mcelog is broken with the Linux kernel used in buster
            $purged_packages = ['mcelog']
        }
        'bullseye': {
            # A dist upgrade to bullseye leaves some old binary packages around, remove those
            $absent_packages = [
                'libsnmp30', 'libdns-export1104', 'libdns1104', 'libisc-export1100', 'libisc1100',
            ]
            $purged_packages = []
        }
        'bookworm': {
            # A dist upgrade to bookworm leaves some old binary packages around, remove those
            $absent_packages = [
                'libboost-filesystem1.74.0', 'libboost-locale1.74.0', 'libboost-log1.74.0', 'libboost-nowide1.74.0',
                'libboost-program-options1.74.0', 'libboost-thread1.74.0', 'libicu67', 'libwsutil12', 'libwireshark14',
                'libwiretap11', 'ruby2.7', 'python3.9-minimal', 'python3.9', 'perl-modules-5.32', 'libpython3.9',
                'libperl5.32', 'libpython3.9-minimal', 'libpython3.9-stdlib', 'libidn11', 'libldap-2.4-2',
                'liburing1', 'libwebp6', 'libcbor0', 'libusb-0.1-4',
            ]
            $purged_packages = []
        }
        default: {
            $absent_packages = []
            $purged_packages = []
        }
    }
    package {$absent_packages: ensure => 'absent'}
    package {$purged_packages: ensure => 'purged'}

    profile::auto_restarts::service { 'lldpd': }
    profile::auto_restarts::service { 'cron': }

    # Safe restarts are supported since systemd 219:
    # * systemd now provides a way to store file descriptors
    # per-service in PID 1. This is useful for daemons to ensure
    # that fds they require are not lost during a daemon
    # restart. The fds are passed to the daemon on the next
    # invocation in the same way socket activation fds are
    # passed. This is now used by journald to ensure that the
    # various sockets connected to all the system's stdout/stderr
    # are not lost when journald is restarted.
    profile::auto_restarts::service { 'systemd-journald': }
}
