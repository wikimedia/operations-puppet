# @summary Set up a check for uncommitted diffs
class profile::conftool::dbctl_client() {
    require ::profile::conftool::client

    ensure_packages(['python3-conftool-dbctl', 'etcd-client'])

    nrpe::plugin { 'check_dbctl_uncommitted_diffs':
        source => 'puppet:///modules/profile/conftool/check_dbctl_uncommitted_diffs.sh'
    }

    nrpe::monitor_service { 'dbctl_uncommitted_diffs':
        ensure         => present,
        description    => 'Uncommitted dbctl configuration changes, check dbctl config diff',
        nrpe_command   => '/usr/local/lib/nagios/plugins/check_dbctl_uncommitted_diffs',
        critical       => false,
        check_interval => 5,
        retry_interval => 5,
        retries        => 3,
        notes_url      => 'https://wikitech.wikimedia.org/wiki/Dbctl#Uncommitted_dbctl_diffs',
        timeout        => 20,
    }
}
