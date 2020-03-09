# @summary class to configure nrpe checks to ensure hosts are not
#          performing a change on every puppet run
class profile::puppetdb::monitoring_agentrun (
    Integer[1,99] $warn = lookup('profile::puppetdb::monitoring_agentrun::warn'),
    Integer[1,99] $crit = lookup('profile::puppetdb::monitoring_agentrun::crit'),
) {

    ensure_packages(['python3-pypuppetdb'])

    file { '/usr/lib/nagios/plugins/check_puppet_run_changes':
        mode    => '0555',
        content => file('profile/puppetdb/check_puppet_run_changes.py'),
        require => Package['python3-pypuppetdb'],
    }

    nrpe::monitor_service{'puppet_run_changes':
        description    => 'Check to ensure host are not preforming a change on every puppet run',
        nrpe_command   => "/usr/lib/nagios/plugins/check_puppet_run_changes -w ${warn} -c ${crit}",
        check_interval => 360,
        retry_interval => 5,
        retry          => 2,
        notes_url      => 'https://wikitech.wikimedia.org/wiki/Puppet#check_puppet_run_changes',
        require        => File['/usr/lib/nagios/plugins/check_puppet_run_changes'],
    }
}
