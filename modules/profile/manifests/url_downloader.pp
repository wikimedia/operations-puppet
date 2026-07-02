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
            $network::constants::all_network_subnets['cloud']['eqiad']['private']['cloud-instances2-b-eqiad']['ipv4'],
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

    firewall::service { 'url_downloader':
        proto    => 'tcp',
        port     => $url_downloader_port,
        src_sets => ['DOMAIN_NETWORKS'],
    }

    prometheus::blackbox::check::http { 'url-downloader.wikimedia.org':
        port           => $url_downloader_port,
        status_matches => [400],
        probe_runbook  => 'https://wikitech.wikimedia.org/wiki/Url-downloader',
    }

    profile::auto_restarts::service { 'squid': }

    # FIXME: this happens to work because webproxy squids run on the same port (8080)
    # squid_exporter's profile should probably read from a different hiera?
    include profile::prometheus::squid_exporter
}
