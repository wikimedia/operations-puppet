class base::remote-syslog {
    if ($::hostname != 'lithium') and ($::instancename != 'deployment-bastion') {

        $syslog_host = $::realm ? {
            'production' => 'syslog.eqiad.wmnet',
            'labs'       => "deployment-bastion.${::site}.wmflabs",
        }

        rsyslog::conf { 'remote_syslog':
            content  => "*.info;mail.none;authpriv.none;cron.none @${syslog_host}",
            priority => 30,
        }
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

# handle syslog permissions (e.g. 'make common logs readable by normal users (RT-2712)')
class base::syslogs (
    $readable = false,
    $logfiles = [ 'syslog', 'messages' ],
    ) {

    define syslogs::readable() {

        file { "/var/log/${name}":
            mode => '0644',
        }
    }

    if $readable == true {
        syslogs::readable { $logfiles: }
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
        ensure => $ensure,
        prio   => '00',
        source => 'puppet:///modules/base/firewall/main-input-default-drop.conf',
    }

    ferm::rule { 'bastion-ssh':
        ensure => $ensure,
        rule   => 'proto tcp dport ssh saddr $BASTION_HOSTS ACCEPT;',
    }

    ferm::rule { 'monitoring-all':
        ensure => $ensure,
        rule   => 'saddr $MONITORING_HOSTS ACCEPT;',
    }
}

class base {
    include apt

    if ($::realm == 'labs') {
        include apt::unattendedupgrades,
            apt::noupgrade
    }

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

        # Labs instances /var is quite small, provide our own default
        # to keep less records (bug 69604).
        file { '/etc/default/acct':
            ensure => present,
            owner  => 'root',
            group  => 'root',
            mode   => '0444',
            source => 'puppet:///modules/base/labs-acct.default',
        }
    } else {
        $certname = undef
    }

    class { 'base::puppet':
        server   => $::realm ? {
            'labs'  => $::site ? {
                'eqiad' => 'virt1000.wikimedia.org',
            },
            default => 'puppet',
        },
        certname => $certname,
    }

    include passwords::root
    include base::grub
    include base::resolving
    include base::remote-syslog
    include base::sysctl
    include ::motd
    include base::standard-packages
    include base::environment
    include base::phaste
    include base::screenconfig
    include ssh::client
    include ssh::server
    include role::salt::minions
    include role::trebuchet
    include nrpe


    # include base::monitor::host.
    # if $nagios_contact_group is set, then use it
    # as the monitor host's contact group.
    class { 'base::monitoring::host':
        contact_group => $::nagios_contact_group ? {
            undef   => 'admins',
            default => $::nagios_contact_group,
        }
    }

    # CA for the new ldap-eqiad/ldap-codfw ldap servers, among
    # other things.
    include certificates::globalsign_ca
    # TODO: Kill the old wmf_ca
    include certificates::wmf_ca
    include certificates::wmf_ca_2014_2017
}
