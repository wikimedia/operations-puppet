# == Class profile::mediawiki::api
#
# Specific settings for the mediawiki API servers
class profile::mediawiki::api {
    # Using fastcgi we need more local ports
    sysctl::parameters { 'raise_port_range':
        values   => { 'net.ipv4.local_port_range' => '22500 65535', },
        priority => 90,
    }

    # Check the load to detect clearly hosts hanging (see T184048, T182568)
    $nproc = $facts['processorcount']
    $warning = join([ $nproc * 0.95, $nproc * 0.8, $nproc * 0.75], ',')
    $critical = join([ $nproc * 1.5, $nproc * 1.1, $nproc * 1], ',')
    # Since we're checking the load, that is already a moving average, we can
    # alarm at the first occurrence
    nrpe::monitor_service { 'cpu_load':
        description  => 'High CPU load on API appserver',
        nrpe_command => "/usr/lib/nagios/plugins/check_load -w ${warning} -c ${critical}",
        retries      => 1,
        notes_url    => 'https://wikitech.wikimedia.org/wiki/Application_servers',
    }
}
