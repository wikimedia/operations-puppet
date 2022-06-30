# SPDX-License-Identifier: Apache-2.0
# @summary install and configure puppet agent
# @param puppetmaster the puppet server
# @param ca_server the ca server
# @param ca_source to source of the CA file
# @param manage_ca_file if true manage the puppet ca file
# @param interval the, in minutes, interval to perform puppet runs
# @param environment the agent environment
# @param serialization_format the serilasation format of catalogs
# @param dns_alt_names a list of dns alt names
# @param certificate_revocation The level of certificate revocation to perform
class profile::puppet::agent(
    String                          $puppetmaster           = lookup('puppetmaster'),
    Optional[String[1]]             $ca_server              = lookup('puppet_ca_server'),
    Stdlib::Filesource              $ca_source              = lookup('puppet_ca_source'),
    Boolean                         $manage_ca_file         = lookup('manage_puppet_ca_file'),
    Integer[1,59]                   $interval               = lookup('profile::puppet::agent::interval'),
    Optional[String[1]]             $environment            = lookup('profile::puppet::agent::environment'),
    Enum['pson', 'json', 'msgpack'] $serialization_format   = lookup('profile::puppet::agent::serialization_format'),
    Array[Stdlib::Fqdn]             $dns_alt_names          = lookup('profile::puppet::agent::dns_alt_names'),
    Optional[Enum['chain', 'leaf']] $certificate_revocation = lookup('profile::puppet::agent::certificate_revocation'),
) {

    class { 'puppet::agent':
        ca_source              => $ca_source,
        manage_ca_file         => $manage_ca_file,
        server                 => $puppetmaster,
        ca_server              => $ca_server,
        dns_alt_names          => $dns_alt_names,
        environment            => $environment,
        certificate_revocation => $certificate_revocation,
    }
    class { 'puppet_statsd':
        statsd_host   => 'statsd.eqiad.wmnet',
        metric_format => 'puppet.<%= metric %>',
    }
    class { 'prometheus::node_puppet_agent': }
    include profile::puppet::client_bucket

    # Mode 0751 to make sure non-root users can access
    # /var/lib/puppet/state/agent_disabled.lock to check if puppet is enabled
    file { '/var/lib/puppet':
        ensure => directory,
        owner  => 'puppet',
        group  => 'puppet',
        mode   => '0751',
    }
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
            content => template('profile/puppet/puppet-run.erb');
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
    }
    $timer_interval = "*:${interval.fqdn_rand}/${interval}:00"

    systemd::timer::job { 'puppet-agent-timer':
        ensure        => present,
        description   => "Run Puppet agent every ${interval} minutes",
        user          => 'root',
        ignore_errors => true,
        command       => '/usr/local/sbin/puppet-run',
        interval      => [
            {'start' => 'OnCalendar', 'interval' => $timer_interval},
            {'start' => 'OnStartupSec', 'interval' => '1min'},
        ],
    }

    logrotate::rule { 'puppet':
        ensure       => present,
        file_glob    => '/var/log/puppet /var/log/puppet.log',
        frequency    => 'daily',
        compress     => true,
        missing_ok   => true,
        not_if_empty => true,
        rotate       => 7,
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
