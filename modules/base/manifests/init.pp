class base::access::dc-techs {
    # add account and sudoers rules for data center techs
    #include accounts::cmjohnson

    # hardy doesn't support sudoers.d; only do sudo_user for lucid and later
    if versioncmp($::lsbdistrelease, '10.04') >= 0 {
        sudo_user { [ 'cmjohnson' ]: privileges => [
            'ALL = (root) NOPASSWD: /sbin/fdisk',
            'ALL = (root) NOPASSWD: /sbin/mdadm',
            'ALL = (root) NOPASSWD: /sbin/parted',
            'ALL = (root) NOPASSWD: /sbin/sfdisk',
            'ALL = (root) NOPASSWD: /usr/bin/MegaCli',
            'ALL = (root) NOPASSWD: /usr/bin/arcconf',
            'ALL = (root) NOPASSWD: /usr/bin/lshw',
            'ALL = (root) NOPASSWD: /usr/sbin/grub-install',
        ]}
    }

}

class base::grub {
    # Disable the 'quiet' kernel command line option so console messages
    # will be printed.
    exec { 'grub1 remove quiet':
        path    => '/bin:/usr/bin',
        command => "sed -i '/^# defoptions.*[= ]quiet /s/quiet //' /boot/grub/menu.lst",
        onlyif  => "grep -q '^# defoptions.*[= ]quiet ' /boot/grub/menu.lst",
        notify  => Exec['update-grub'],
    }

    exec { 'grub2 remove quiet':
        path    => '/bin:/usr/bin',
        command => "sed -i '/^GRUB_CMDLINE_LINUX_DEFAULT=\"quiet splash\"/s/quiet splash//' /etc/default/grub",
        onlyif  => "grep -q '^GRUB_CMDLINE_LINUX_DEFAULT=\"quiet splash\"' /etc/default/grub",
        notify  => Exec['update-grub'],
    }

    # Ubuntu Precise Pangolin no longer has a server kernel flavour.
    # The generic flavour uses the CFQ I/O scheduler, which is rather
    # suboptimal for some of our I/O work loads. Override with deadline.
    # (the installer does this too, but not for Lucid->Precise upgrades)
    if $::lsbdistid == 'Ubuntu' and versioncmp($::lsbdistrelease, '12.04') >= 0 {
        exec { 'grub1 iosched deadline':
            path    => "/bin:/usr/bin",
            command => "sed -i '/^# kopt=/s/\$/ elevator=deadline/' /boot/grub/menu.lst",
            unless  => "grep -q '^# kopt=.*elevator=deadline' /boot/grub/menu.lst",
            onlyif  => "test -f /boot/grub/menu.lst",
            notify  => Exec["update-grub"],
        }

        exec { 'grub2 iosched deadline':
            path    => "/bin:/usr/bin",
            command => "sed -i '/^GRUB_CMDLINE_LINUX=/s/\\\"\$/ elevator=deadline\\\"/' /etc/default/grub",
            unless  => "grep -q '^GRUB_CMDLINE_LINUX=.*elevator=deadline' /etc/default/grub",
            onlyif  => 'test -f /etc/default/grub',
            notify  => Exec['update-grub'];
        }
    }

    exec { 'update-grub':
        refreshonly => true,
        path        => '/bin:/usr/bin:/sbin:/usr/sbin',
    }
}

class base::puppet($server='puppet', $certname=undef) {

    include passwords::puppet::database

    ## run puppet by cron and
    ## rotate puppet logs generated by cron
    ## This is in mins. Do not set this to 0 or > 60
    $interval = 30
    $crontime = fqdn_rand(60)
    # Calculate freshness interval in seconds (hence *60)
    $freshnessinterval = $interval * 60 * 6

    package { [ 'puppet', 'facter', 'coreutils' ]:
        ensure  => latest,
        require => Apt::Puppet['base']
    }

    if $::lsbdistid == 'Ubuntu' and (versioncmp($::lsbdistrelease, '10.04') == 0 or versioncmp($::lsbdistrelease, '8.04') == 0) {
        package {'timeout':
            ensure => latest,
        }
    }

    # monitoring via snmp traps
    package { 'snmp':
        ensure => latest,
    }

    file { '/etc/snmp':
        ensure  => directory,
        owner   => 'root',
        group   => 'root',
        mode    => '0644',
        require => Package['snmp'],
    }

    file { '/etc/snmp/snmp.conf':
        ensure  => present,
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        content => template('base/snmp.conf.erb'),
        require => [ Package['snmp'], File['/etc/snmp'] ],
    }

    monitor_service { 'puppet freshness':
        description     => 'Puppet freshness',
        check_command   => 'puppet-FAIL',
        passive         => 'true',
        freshness       => $freshnessinterval,
        retries         => 1,
    }

    case $::realm {
        'production': {
            exec {  'neon puppet snmp trap':
                command => "snmptrap -v 1 -c public neon.wikimedia.org .1.3.6.1.4.1.33298 `hostname` 6 1004 `uptime | awk '{ split(\$3,a,\":\"); print (a[1]*60+a[2])*60 }'`",
                path    => '/bin:/usr/bin',
                require => Package['snmp'],
            }
        }
        'labs': {
            # The next two notifications are read in by the labsstatus.rb puppet report handler.
            #  It needs to know project/hostname for nova access.
            notify{"instanceproject: ${::instanceproject}":}
            notify{"hostname: ${::instancename}":}
            exec { 'puppet snmp trap':
                command => "snmptrap -v 1 -c public icinga.eqiad.wmflabs .1.3.6.1.4.1.33298 ${::instancename}.${::site}.wmflabs 6 1004 `uptime | awk '{ split(\$3,a,\":\"); print (a[1]*60+a[2])*60 }'`",
                path    => '/bin:/usr/bin',
                require => Package['snmp'],
            }
        }
        default: {
            err('realm must be either "labs" or "production".')
        }
    }

    file { '/etc/default/puppet':
        owner  => 'root',
        group  => 'root',
        mode   => '0444',
        source => 'puppet:///modules/base/puppet/puppet.default',
    }

    file { '/etc/puppet/puppet.conf':
        ensure => 'file',
        owner  => 'root',
        group  => 'root',
        mode   => '0444',
        notify => Exec['compile puppet.conf'],
    }

    file { '/etc/puppet/puppet.conf.d/':
        ensure => directory,
        owner  => 'root',
        group  => 'root',
        mode   => '0550',
    }

    file { '/etc/puppet/puppet.conf.d/10-main.conf':
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        content => template('base/puppet.conf.d/10-main.conf.erb'),
        notify  => Exec['compile puppet.conf'],
    }

    if $::realm == 'labs' {
        # Clear master certs if puppet.conf changed
        exec { 'delete master certs':
            path        => '/usr/bin:/bin',
            command     => 'rm -f /var/lib/puppet/ssl/certs/ca.pem; rm -f /var/lib/puppet/ssl/crl.pem; rm -f /root/allowcertdeletion',
            onlyif      => 'test -f /root/allowcertdeletion',
            subscribe   => File['/etc/puppet/puppet.conf.d/10-main.conf'],
            refreshonly => true,
        }
    }

    file { '/etc/init.d/puppet':
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
        source => 'puppet:///modules/base/puppet/puppet.init',
    }

    class { 'puppet_statsd':
        statsd_host   => 'statsd.eqiad.wmnet',
        metric_format => 'puppet.<%= metric %>',
    }

    # Compile /etc/puppet/puppet.conf from individual files in /etc/puppet/puppet.conf.d
    exec { 'compile puppet.conf':
        path        => '/usr/bin:/bin',
        command     => "cat /etc/puppet/puppet.conf.d/??-*.conf > /etc/puppet/puppet.conf",
        refreshonly => true,
    }

    ## do not use puppet agent
    service {'puppet':
        ensure => stopped,
        enable => false,
    }

    file { '/etc/cron.d/puppet':
        require => File['/etc/default/puppet'],
        mode    => '0444',
        owner   => 'root',
        group   => 'root',
        content => template('base/puppet.cron.erb'),
    }

    file { '/etc/logrotate.d/puppet':
        mode   => '0444',
        owner  => 'root',
        group  => 'root',
        source => 'puppet:///modules/base/logrotate/puppet',
    }

    # Report the last puppet run in MOTD
    if $::lsbdistid == 'Ubuntu' and versioncmp($::lsbdistrelease, '9.10') >= 0 {
        file { '/etc/update-motd.d/97-last-puppet-run':
            owner   => 'root',
            group   => 'root',
            mode    => '0555',
            source  => 'puppet:///modules/base/puppet/97-last-puppet-run',
        }
    }
}

class base::remote-syslog {
    if ($::lsbdistid == 'Ubuntu') and
            ($::hostname != 'nfs1') and
            ($::hostname != 'aluminium') and
            ($::instancename != 'deployment-bastion') {

        $syslog_host = $::realm ? {
            'production' => 'syslog.eqiad.wmnet',
            'labs'       => 'deployment-bastion.eqiad.wmflabs',
        }

        rsyslog::conf { 'remote_syslog':
            content  => "*.info;mail.none;authpriv.none;cron.none @${syslog_host}",
            priority => 30,
        }
    }
}

# Class: base::packages::emacs
#
# Installs emacs package
class base::packages::emacs {
    package { 'emacs23':
        ensure => 'installed',
        alias  => 'emacs',
    }
}

class base::instance-upstarts {

    file { '/etc/init/ttyS0.conf':
        owner  => 'root',
        group  => 'root',
        mode   => '0444',
        source => 'puppet:///modules/base/upstart/ttyS0.conf';
    }

}

class base::screenconfig {
    if $::lsbdistid == 'Ubuntu' {
        file { '/root/.screenrc':
            ensure => present,
            owner  => 'root',
            group  => 'root',
            mode   => '0444',
            source => 'puppet:///modules/base/screenrc',
        }
    }
}

# handle syslog permissions (e.g. 'make common logs readable by normal users (RT-2712)')
class base::syslogs($readable = false) {

    $common_logs = [ 'syslog', 'messages' ]

    define syslogs::readable() {

        file { "/var/log/${name}":
            mode => '0644',
        }
    }

    if $readable == true {
        syslogs::readable { $common_logs: }
    }
}


class base::tcptweaks {
    Class[base::puppet] -> Class[base::tcptweaks]

    # unneeded since Linux 2.6.39, i.e. Ubuntu 11.10 Oneiric Ocelot
    if $::lsbdistid == 'Ubuntu' and versioncmp($::lsbdistrelease, '11.10') < 0 {
        file { '/etc/network/if-up.d/initcwnd':
            ensure  => present,
            content => template('base/initcwnd.erb'),
            mode    => '0555',
            owner   => 'root',
            group   => 'root',
        }

        exec { '/etc/network/if-up.d/initcwnd':
            require     => File['/etc/network/if-up.d/initcwnd'],
            subscribe   => File['/etc/network/if-up.d/initcwnd'],
            refreshonly => true,
        }
    } else {
        file { '/etc/network/if-up.d/initcwnd':
            ensure  => absent,
        }
    }
}

# Don't include this sub class on all hosts yet
# NOTE: Policy is DROP by default
class base::firewall($ensure = 'present') {
    include network::constants
    include ferm

    $defscontent = $::realm ? {
        'labs'  => template('base/firewall/defs.erb', 'base/firewall/defs.labs.erb'),
        default => template('base/firewall/defs.erb'),
    }
    ferm::conf { 'defs':
        # defs can always be present.
        # They don't actually do firewalling.
        ensure  => 'present',
        prio    => '00',
        content => $defscontent,
    }

    ferm::conf { 'main':
        ensure  => $ensure,
        prio    => '00',
        source  => 'puppet:///modules/base/firewall/main-input-default-drop.conf',
    }

    ferm::rule { 'bastion-ssh':
        ensure => $ensure,
        rule   => 'proto tcp dport ssh saddr $BASTION_HOSTS ACCEPT;',
    }

    ferm::rule { 'icinga-all':
        ensure => $ensure,
        rule   => 'saddr $MONITORING_HOSTS ACCEPT;',
    }
}

class base {
    include apt
    include apt::update

    if ($::realm == 'labs') {
        include apt::unattendedupgrades,
            apt::noupgrade
    }

    include base::tcptweaks

    file { '/usr/local/sbin':
        ensure => directory,
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
    }

    if ($::realm == 'labs') {
        # For labs, use instanceid.domain rather than the fqdn
        # to ensure we're always using a unique certname.
        # $::ec2id is a fact that queries the instance metadata
        if($::ec2id == '') {
            fail('Failed to fetch instance ID')
        }
        $certname = "${::ec2id}.${::domain}"
    } else {
        $certname = undef
    }

    class { 'base::puppet':
        server => $::realm ? {
            'labs' => $::site ? {
                'pmtpa' => 'virt0.wikimedia.org',
                'eqiad' => 'virt1000.wikimedia.org',
            },
            default => 'puppet',
        },
        certname => $certname,
    }

    include passwords::root,
        base::grub,
        base::resolving,
        base::remote-syslog,
        base::sysctl,
        base::motd,
        base::vimconfig,
        base::standard-packages,
        base::environment,
        base::platform,
        base::access::dc-techs,
        base::screenconfig,
        ssh::client,
        ssh::server,
        role::salt::minions,
        nrpe


    # include base::monitor::host.
    # if $nagios_contact_group is set, then use it
    # as the monitor host's contact group.
    class { 'base::monitoring::host':
        contact_group => $::nagios_contact_group ? {
            undef     => 'admins',
            default   => $::nagios_contact_group,
        }
    }
}
