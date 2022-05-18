class profile::mediawiki::monitor_versions(
  $deployment_host = lookup('deployment_server'),
) {

    ensure_packages('python3-requests')

    nrpe::plugin { 'check_mw_versions':
        source => 'puppet:///modules/profile/mediawiki/monitor_versions/check_mw_versions.py',
    }

    nrpe::monitor_service { 'mw_wikiversion_difference':
        ensure         => present,
        description    => 'Ensure local MW versions match expected deployment',
        nrpe_command   => "/usr/local/lib/nagios/plugins/check_mw_versions --deployhost ${deployment_host}",
        notes_url      => 'https://wikitech.wikimedia.org/wiki/Application_servers',
        critical       => false,
        check_interval => 5,
        retry_interval => 5,
        retries        => 3,
        timeout        => 20,
    }

}
