# @summary class to configure nrpe checks to ensure hosts are not
#          performing a change on every puppet run
class profile::cumin::monitoring_agentrun (
    Integer[1,99] $warn = lookup('profile::cumin::monitoring_agentrun::warn'),
    Integer[1,99] $crit = lookup('profile::cumin::monitoring_agentrun::crit'),
) {

    ensure_packages(['python3-pypuppetdb'])

    file { '/usr/lib/nagios/plugins/check_puppet_run_changes':
        ensure => absent,
    }

    nrpe::plugin { 'check_puppet_run_changes':
        source  => 'puppet:///modules/profile/cumin/check_puppet_run_changes.py',
        require => Package['python3-pypuppetdb'],
    }

    $nrpe_command = @("COMMAND"/L)
    /usr/local/lib/nagios/plugins/check_puppet_run_changes \
    -w ${warn} -c ${crit} \
    --ssl-key ${facts['puppet_config']['hostprivkey']} \
    --ssl-cert ${facts['puppet_config']['hostcert']} \
    --ssl-ca ${facts['puppet_config']['localcacert']}
    | COMMAND
    sudo::user {'check_puppet_run command':
        user       => 'nagios',
        privileges => ["ALL = NOPASSWD: ${nrpe_command}"],
    }
    nrpe::monitor_service{'puppet_run_changes':
        description    => 'Ensure hosts are not performing a change on every puppet run',
        nrpe_command   => "sudo ${nrpe_command}",
        check_interval => 360,
        retry_interval => 5,
        retries        => 2,
        notes_url      => 'https://wikitech.wikimedia.org/wiki/Puppet#check_puppet_run_changes',
    }
}
