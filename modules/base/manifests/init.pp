
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
    exec {
        'grub1 remove quiet':
            path => '/bin:/usr/bin',
            command => "sed -i '/^# defoptions.*[= ]quiet /s/quiet //' /boot/grub/menu.lst",
            onlyif => "grep -q '^# defoptions.*[= ]quiet ' /boot/grub/menu.lst",
            notify => Exec['update-grub'];
        'grub2 remove quiet':
            path => '/bin:/usr/bin',
            command => "sed -i '/^GRUB_CMDLINE_LINUX_DEFAULT=\"quiet splash\"/s/quiet splash//' /etc/default/grub",
            onlyif => "grep -q '^GRUB_CMDLINE_LINUX_DEFAULT=\"quiet splash\"' /etc/default/grub",
            notify => Exec['update-grub'];
    }

    # Ubuntu Precise Pangolin no longer has a server kernel flavour.
    # The generic flavour uses the CFQ I/O scheduler, which is rather
    # suboptimal for some of our I/O work loads. Override with deadline.
    # (the installer does this too, but not for Lucid->Precise upgrades)
    if $::lsbdistid == "Ubuntu" and versioncmp($::lsbdistrelease, "12.04") >= 0 {
        exec {
            'grub1 iosched deadline':
                path => "/bin:/usr/bin",
                command => "sed -i '/^# kopt=/s/\$/ elevator=deadline/' /boot/grub/menu.lst",
                unless => "grep -q '^# kopt=.*elevator=deadline' /boot/grub/menu.lst",
                onlyif => "test -f /boot/grub/menu.lst",
                notify => Exec["update-grub"];
            'grub2 iosched deadline':
                path => "/bin:/usr/bin",
                command => "sed -i '/^GRUB_CMDLINE_LINUX=/s/\\\"\$/ elevator=deadline\\\"/' /etc/default/grub",
                unless => "grep -q '^GRUB_CMDLINE_LINUX=.*elevator=deadline' /etc/default/grub",
                onlyif => 'test -f /etc/default/grub',
                notify => Exec['update-grub'];
        }
    }

    exec { 'update-grub':
        refreshonly => true,
        path => "/bin:/usr/bin:/sbin:/usr/sbin"
    }
}

class base::puppet($server='puppet', $certname=undef) {

    include passwords::puppet::database

    package { [ 'puppet', 'facter', 'coreutils' ]:
        ensure => latest;
    }

    if $::lsbdistid == 'Ubuntu' and (versioncmp($::lsbdistrelease, '10.04') == 0 or versioncmp($::lsbdistrelease, '8.04') == 0) {
        package {'timeout':
            ensure => latest;
        }
    }

    # monitoring via snmp traps
    package { [ 'snmp' ]:
        ensure => latest;
    }

    file {
        '/etc/snmp':
            ensure => directory,
            owner => root,
            group => root,
            mode  => 0644,
            require => Package['snmp'];
        '/etc/snmp/snmp.conf':
            ensure => present,
            owner => root,
            group => root,
            mode  => 0444,
            content => template('base/snmp.conf.erb'),
            require => [ Package['snmp'], File['/etc/snmp'] ];
    }

    monitor_service { 'puppet freshness': description => 'Puppet freshness', check_command => 'puppet-FAIL', passive => 'true', freshness => 36000, retries => 1 ; }

    case $::realm {
        'production': {
            exec {  'neon puppet snmp trap':
                    command => "snmptrap -v 1 -c public neon.wikimedia.org .1.3.6.1.4.1.33298 `hostname` 6 1004 `uptime | awk '{ split(\$3,a,\":\"); print (a[1]*60+a[2])*60 }'`",
                    path => '/bin:/usr/bin',
                    require => Package['snmp']
            }
        }
        'labs': {
            exec { 'puppet snmp trap':
                command => "snmptrap -v 1 -c public nagios-main.pmtpa.wmflabs .1.3.6.1.4.1.33298 ${::instancename}.${::site}.wmflabs 6 1004 `uptime | awk '{ split(\$3,a,\":\"); print (a[1]*60+a[2])*60 }'`",
                path => "/bin:/usr/bin",
                require => Package['snmp']
            }
        }
        default: {
            err('realm must be either "labs" or "production".')
        }
    }

    file {
        '/etc/default/puppet':
            owner => root,
            group => root,
            mode  => 0444,
            source => 'puppet:///modules/base/puppet/puppet.default';
        '/etc/puppet/puppet.conf':
            owner => root,
            group => root,
            mode => 0444,
            ensure => file,
            notify => Exec['compile puppet.conf'];
        '/etc/puppet/puppet.conf.d/':
            owner => root,
            group => root,
            mode => 0550,
            ensure => directory;
        '/etc/puppet/puppet.conf.d/10-main.conf':
            owner => root,
            group => root,
            mode  => 0444,
            content => template("base/puppet.conf.d/10-main.conf.erb"),
            notify => Exec["compile puppet.conf"];
        '/etc/init.d/puppet':
            owner => root,
            group => root,
            mode => 0555,
            source => 'puppet:///modules/base/puppet/puppet.init';
    }

    class { 'puppet_statsd':
        statsd_host   => 'tungsten.eqiad.wmnet',
        metric_format => 'puppet.<%= metric %>',
    }

    # Compile /etc/puppet/puppet.conf from individual files in /etc/puppet/puppet.conf.d
    exec { 'compile puppet.conf':
        path => '/usr/bin:/bin',
        command => "cat /etc/puppet/puppet.conf.d/??-*.conf > /etc/puppet/puppet.conf",
        refreshonly => true;
    }

    # Keep puppet running -- no longer. now via cron
    cron {
        restartpuppet:
            require => File[ [ '/etc/default/puppet' ] ],
            command => '/etc/init.d/puppet restart > /dev/null',
            user => root,
            # Restart every 4 hours to avoid the runs bunching up and causing an
            # overload of the master every 40 mins. This can be reverted back to a
            # daily restart after we switch to puppet 2.7.14+ since that version
            # uses a scheduling algorithm which should be more resistant to
            # bunching.
            hour => [0, 4, 8, 12, 16, 20],
            minute => 37,
            ensure => absent;
        remove-old-lockfile:
            require => Package[puppet],
            command => "[ -f /var/lib/puppet/state/puppetdlock ] && find /var/lib/puppet/state/puppetdlock -ctime +1 -delete",
            user => root,
            minute => 43,
            ensure => absent;
    }

    ## do not use puppet agent
    service {"puppet":
        enable => false,
        ensure => stopped;
    }

    ## run puppet by cron and
    ## rotate puppet logs generated by cron
    $crontime = fqdn_rand(60)

    file {
        "/etc/cron.d/puppet":
            require => File[ [ "/etc/default/puppet" ] ],
            mode => 0444,
            owner => root,
            group => root,
            content => template("base/puppet.cron.erb");
        "/etc/logrotate.d/puppet":
            mode => 0444,
            owner => root,
            group => root,
            source => "puppet:///modules/base/logrotate/puppet";
    }

    # Report the last puppet run in MOTD
    if $::lsbdistid == "Ubuntu" and versioncmp($::lsbdistrelease, "9.10") >= 0 {
        file { "/etc/update-motd.d/97-last-puppet-run":
            source => "puppet:///modules/base/puppet/97-last-puppet-run",
            mode => 0555;
        }
    }
}

class base::remote-syslog {
    if ($::lsbdistid == "Ubuntu") and
            ($::hostname != "nfs1") and
            ($::hostname != "nfs2") and
            ($::hostname != "aluminium") and
            ($::instancename != 'deployment-bastion') {
        package { rsyslog:
            ensure => latest;
        }

        # remote syslog destination
        case $::realm {
            'production': {
                if( $::site != '(undefined)' ) {
                    $syslog_remote_real = "syslog.${::site}.wmnet"
                }
            }
            'labs': {
                # Per labs project syslog:
                case $::instanceproject {
                    'deployment-prep': {
                        $syslog_remote_real = 'deployment-bastion.pmtpa.wmflabs'
                    }
                    default: {
                        $syslog_remote_real = 'i-000003a9.pmtpa.wmflabs:5544'
                    }
                }
            }
        }

        $ensure_remote = $syslog_remote_real ? {
            ''  => absent,
            default => present,
        }

        file { "/etc/rsyslog.d/90-remote-syslog.conf":
            ensure => absent;
        }

        file { "/etc/rsyslog.d/30-remote-syslog.conf":
            ensure => $ensure_remote,
            require => Package[rsyslog],
            owner => root,
            group => root,
            mode => 0444,
            content => "*.info;mail.none;authpriv.none;cron.none    @${syslog_remote_real}\n",
        }

        service { rsyslog:
            require => Package[rsyslog],
            subscribe => File["/etc/rsyslog.d/30-remote-syslog.conf"],
            ensure => running;
        }
    }
}

# Class: base::packages::emacs
#
# Installs emacs package
class base::packages::emacs {
    package { "emacs23":
        ensure => "installed",
        alias  => "emacs",
    }
}

class base::decommissioned {
    if $::hostname in $::decommissioned_servers {
        system::role { "base::decommissioned": description => "DECOMMISSIONED server" }
    }
}

class base::instance-upstarts {

    file {"/etc/init/ttyS0.conf":
        owner => root,
        group => root,
        mode => 0444,
        source => 'puppet:///modules/base/upstart/ttyS0.conf';
    }

}

class base::screenconfig {
    if $::lsbdistid == "Ubuntu" {
        file {  "/root/.screenrc":
            owner => root,
            group => root,
            mode => 0444,
            source => "puppet:///modules/base/screenrc",
            ensure => present;
        }
    }
}

# handle syslog permissions (e.g. 'make common logs readable by normal users (RT-2712)')
class base::syslogs($readable = 'false') {

    $common_logs = [ "syslog", "messages" ]

    define syslogs::readable() {

        file { "/var/log/${name}":
            mode => '0644',
        }
    }

    if $readable == 'true' {
        syslogs::readable { $common_logs: }
    }
}


class base::tcptweaks {
    Class[base::puppet] -> Class[base::tcptweaks]

    file { "/etc/network/if-up.d/initcwnd":
        content => template("base/initcwnd.erb"),
        mode => 0555,
        owner => root,
        group => root,
        ensure => present;
    }

    exec { "/etc/network/if-up.d/initcwnd":
        require => File["/etc/network/if-up.d/initcwnd"],
        subscribe => File["/etc/network/if-up.d/initcwnd"],
        refreshonly => true;
    }
}

# Don't include this sub class on all hosts yet
class base::firewall {
    include ferm

    ferm::conf { 'main':
        ensure  => present,
        prio    => '00',
        # we also have a default DROP around, postpone its usage for later
        source  => 'puppet:///modules/base/firewall/main-minimal.conf',
    }

    ferm::conf { 'defs':
        ensure  => present,
        prio    => '00',
        source  => "puppet:///modules/base/firewall/defs.${::realm}",
    }

    ferm::rule { 'bastion-ssh':
        ensure => present,
        rule   => 'proto tcp dport ssh saddr $BASTION ACCEPT;',
    }
}

class base {
    include apt
    include apt::update

    if ($::realm == "labs") {
        include apt::unattendedupgrades,
            apt::noupgrade
    }

    include base::tcptweaks

    file { "/usr/local/sbin":
        ensure => directory,
        owner  => root,
        group  => root,
        mode   => 0755;
    }

    class { base::puppet:
        server => $::realm ? {
            'labs' => $::site ? {
                'pmtpa' => 'virt0.wikimedia.org',
                'eqiad' => 'virt1000.wikimedia.org',
            },
            default => "puppet",
        },
        certname => $::realm ? {
            # For labs, use instanceid.domain rather than the fqdn
            # to ensure we're always using a unique certname.
            # dc is an attribute from LDAP, it's set as the instanceid.
            'labs' => "${::dc}",
            default => undef,
        },
    }

    include passwords::root,
        base::decommissioned,
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
        role::salt::minions


    # include base::monitor::host.
    # if $nagios_contact_group is set, then use it
    # as the monitor host's contact group.
    class { "base::monitoring::host":
        contact_group => $::nagios_contact_group ? {
            undef   => "admins",
            default => $::nagios_contact_group,
        }
    }

    if $::realm == "labs" {
        include base::instance-upstarts,
            gluster::client

        # Storage backend to use for /home & /data/project
        # Configured on a per project basis inside puppet since we do not have any
        # other good way to do so yet.
        # FIXME  this is ugly and need to be removed whenever we got rid of
        # the Gluster shared storage.
        if $::instanceproject == 'deployment-prep' {
                include role::labsnfs::client
        }

        # make common logs readable
        class {'base::syslogs': readable => 'true'; }

        # Add directory for data automounts
        file { "/data":
            ensure => directory,
            owner => root,
            group => root,
            mode => 0755;
        }
        # Add directory for public (ro) automounts
        file { "/public":
            ensure => directory,
            owner => root,
            group => root,
            mode => 0755;
        }
    }
}
