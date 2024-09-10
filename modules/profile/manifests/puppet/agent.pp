# SPDX-License-Identifier: Apache-2.0
# @summary install and configure puppet agent
# @param puppetmaster the puppet server
# @param ca_server the ca server
# @param site_nearest_core list of mappings to a sites nearest core
# @param use_srv_records if true use SRV records to resolve the puppet server and ca server
# @param srv_domain the domain to use when resolving SRV records.  puppet will look for records al
#   _x-puppet._tcp.$srv_domain and _x-puppet-ca._tcp.$srv_domain
# @param interval the, in minutes, interval to perform puppet runs
# @param force_puppet7 on bullseye hosts this enables an experimental puppet7
#   backport.  however this is known to have some issues with puppetmaster5
#   specifically related to certificate provisioning.  On bookworm this flag
#   disables the puppet5 forward-port so systems use the default Debian package
# @param timer_seed Add ability to seed the systemd timer.  usefull if jobs happen to collide
# @param environment the agent environment
# @param serialization_format the serilasation format of catalogs
# @param dns_alt_names a list of dns alt names
# @param certificate_revocation The level of certificate revocation to perform
# @param create_timer whether to create the systemd agent timer
class profile::puppet::agent (
    String                             $puppetmaster           = lookup('puppetmaster'),
    Optional[String[1]]                $ca_server              = lookup('puppet_ca_server'),
    Hash[Wmflib::Sites, Wmflib::Sites] $site_nearest_core      = lookup('site_nearest_core'),
    Boolean                            $use_srv_records        = lookup('profile::puppet::agent::use_srv_records'),
    Optional[Stdlib::Fqdn]             $srv_domain             = lookup('profile::puppet::agent::srv_domain'),
    Integer[1,59]                      $interval               = lookup('profile::puppet::agent::interval'),
    Boolean                            $force_puppet7          = lookup('profile::puppet::agent::force_puppet7'),
    Optional[String[1]]                $timer_seed             = lookup('profile::puppet::agent::timer_seed'),
    Optional[String[1]]                $environment            = lookup('profile::puppet::agent::environment'),
    Enum['pson', 'json', 'msgpack']    $serialization_format   = lookup('profile::puppet::agent::serialization_format'),
    Array[Stdlib::Fqdn]                $dns_alt_names          = lookup('profile::puppet::agent::dns_alt_names'),
    Boolean                            $create_timer           = lookup('profile::puppet::agent::create_timer', {'default_value' => true}),
    Optional[Enum['chain', 'leaf', 'false']] $certificate_revocation = lookup('profile::puppet::agent::certificate_revocation'),
) {
    if $force_puppet7 {
        if debian::codename::lt('bullseye') {
            # We only have packages for bullseye currently
            $msg = wmflib::ansi::fg('puppet7 is not available on buster.  forcing this is likely going to cause issue.', 'red')
            notify { $msg: }
        } elsif debian::codename::eq('bullseye') {
        # Use the backported version
            apt::package_from_component { 'puppet':
                component => 'component/puppet7',
                priority  => 1002,
            }
        } else {
            # Add a priority on the debian repos as we have a forward port in wikimedia/main
            apt::pin { 'puppet':
                pin      => 'release l=Debian',
                priority => 1003,
            }
        }
        # Force leaf on puppet7 T330490
        $_certificate_revocation = $certificate_revocation.lest || { 'leaf' }
        $_use_srv_records = $use_srv_records
        $_srv_domain = $srv_domain.lest || {
            $::site ? {
                /codfw|eqiad/ => "${::site}.wmnet",
                default       => "${site_nearest_core[$::site]}.wmnet",
            }
        }
    } else {
        $_certificate_revocation = $certificate_revocation
        $_use_srv_records = false
        $_srv_domain = undef

        motd::message { 'Host is still on Puppet 5':
            color    => 'yellow',
            priority => 90,
        }
    }
    class { 'puppet::agent':
        server                 => $puppetmaster,
        ca_server              => $ca_server,
        use_srv_records        => $_use_srv_records,
        srv_domain             => $_srv_domain,
        dns_alt_names          => $dns_alt_names,
        environment            => $environment,
        certificate_revocation => $_certificate_revocation,
    }
    class { 'puppet_statsd':
        statsd_host   => 'statsd.eqiad.wmnet',
        metric_format => 'puppet.<%= metric %>',
    }
    class { 'prometheus::node_puppet_agent': }
    include profile::puppet::client_bucket

    ensure_packages([
        # needed for the ssh_ca_host_certificate custom fact
        'ruby-net-ssh',
        # needed by the locate-unmanaged script
        'python3-yaml',
    ])

    # Mode 0751 to make sure non-root users can access
    # /var/lib/puppet/state/agent_disabled.lock to check if puppet is enabled
    ensure_resource(
        'file',
        '/var/lib/puppet',
        {
            'ensure' => 'directory',
            'owner'  => 'puppet',
            'group'  => 'puppet',
            'mode'   => '0751',
        },
    )
    # WMF helper scripts
    file {
        default:
            ensure => file,
            mode   => '0555',
            owner  => 'root',
            group  => 'root';
        '/usr/local/share/bash/puppet-common.sh':
            source => 'puppet:///modules/profile/puppet/bin/puppet-common.sh';
        '/usr/local/sbin/puppet-run':
            source => 'puppet:///modules/profile/puppet/bin/puppet-run.sh';
        '/usr/local/bin/puppet-enabled':
            source => 'puppet:///modules/profile/puppet/bin/puppet-enabled';
        '/usr/local/sbin/disable-puppet':
            mode   => '0550',
            source => 'puppet:///modules/profile/puppet/bin/disable-puppet';
        '/usr/local/sbin/enable-puppet':
            mode   => '0550',
            source => 'puppet:///modules/profile/puppet/bin/enable-puppet';
        '/usr/local/sbin/run-puppet-agent':
            mode   => '0550',
            source => 'puppet:///modules/profile/puppet/bin/run-puppet-agent';
        '/usr/local/sbin/run-no-puppet':
            mode   => '0550',
            source => 'puppet:///modules/profile/puppet/bin/run-no-puppet';
        '/usr/local/sbin/locate-unmanaged':
            mode   => '0550',
            source => 'puppet:///modules/profile/puppet/bin/locate-unmanaged.py';
    }
    $min = $interval.fqdn_rand($timer_seed)
    $timer_interval = "*:${min}/${interval}:00"

    if $create_timer {
        systemd::timer::job { 'puppet-agent-timer':
            ensure        => present,
            description   => "Run Puppet agent every ${interval} minutes",
            user          => 'root',
            ignore_errors => true,
            command       => '/usr/local/sbin/puppet-run',
            interval      => [
                { 'start' => 'OnCalendar', 'interval' => $timer_interval },
                { 'start' => 'OnStartupSec', 'interval' => '1min' },
            ],
        }
    }

    logrotate::rule { 'puppet':
        ensure       => present,
        file_glob    => '/var/log/puppet /var/log/puppet.log',
        frequency    => 'daily',
        compress     => true,
        missing_ok   => true,
        not_if_empty => true,
        rotate       => 7,
        post_rotate  => ['/usr/lib/rsyslog/rsyslog-rotate'],
    }

    rsyslog::conf { 'puppet-agent':
        source   => 'puppet:///modules/profile/puppet/rsyslog.conf',
        priority => 10,
        require  => File['/etc/logrotate.d/puppet'],
    }
    motd::script { 'last-puppet-run':
        ensure   => present,
        priority => 97,
        source   => 'puppet:///modules/profile/puppet/97-last-puppet-run',
    }
}
