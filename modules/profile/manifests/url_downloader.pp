# SPDX-License-Identifier: Apache-2.0
# Class: profile::url_downloader
#
class profile::url_downloader (
    Stdlib::Port $url_downloader_port = lookup('profile::url_downloader::url_downloader_port'),
) {

    include network::constants

    # TODO rework all this ugly mess
    if $::realm == 'production' {
        $wikimedia = $network::constants::mw_appserver_networks
    } elsif $::realm == 'labs' {
        $wikimedia = [
            $network::constants::all_network_subnets['labs']['eqiad']['private']['cloud-instances2-b-eqiad']['ipv4'],
        ]
    } else {
        fail('Dont use this role outside of wikimedia')
    }
    # Don't allow using the proxy to reach internal hosts
    $towikimedia = $network::constants::mw_appserver_networks_private

    $syslog_facility = 'local0'
    $syslog_priority = 'info'
    $config_content = template('profile/url_downloader/squid.conf.erb')

    include profile::logrotate

    $rsyslog_content = @("CONF"/L$)
    # Send squid access logs
    if \$programname startswith 'squid' \
    and  \$syslogfacility-text == '${syslog_facility}' \
    and \$syslogpriority-text == '${syslog_priority}' \
    then /var/log/squid/access.log
    &~
    | CONF

    rsyslog::conf { 'squid-access':
        content => $rsyslog_content,
    }

    class { 'squid':
        config_content      => $config_content,
        logrotate_frequency => $profile::logrotate::hourly.bool2str('hourly', 'daily'),
    }

    ferm::service { 'url_downloader':
        proto  => 'tcp',
        port   => $url_downloader_port,
        srange => '$DOMAIN_NETWORKS',
    }

    monitoring::service { 'url_downloader':
        ensure        => absent,
        description   => 'url_downloader',
        check_command => "check_tcp_ip!url-downloader.wikimedia.org!${url_downloader_port}",
        notes_url     => 'https://wikitech.wikimedia.org/wiki/Url-downloader',
    }

    prometheus::blackbox::check::http { 'url-downloader.wikimedia.org':
        port           => $url_downloader_port,
        status_matches => [400],
        probe_runbook  => 'https://wikitech.wikimedia.org/wiki/Url-downloader',
    }

    profile::auto_restarts::service { 'squid': }
}
