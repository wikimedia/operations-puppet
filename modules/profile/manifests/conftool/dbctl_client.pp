class profile::conftool::dbctl_client() {
    require ::profile::conftool::client

    require_package('python3-conftool-dbctl', 'etcd-client')

    # Set up a check for uncommitted diffs
    $uncom_diffs_filename = '/usr/local/lib/nagios/plugins/check_dbctl_uncommitted_diffs'

    file { $uncom_diffs_filename:
        ensure => present,
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
        source => 'puppet:///modules/profile/conftool/check_dbctl_uncommitted_diffs.sh'
    }

    nrpe::monitor_service { 'dbctl_uncommitted_diffs':
        ensure         => present,
        description    => 'Uncommitted dbctl configuration changes, check dbctl config diff',
        nrpe_command   => $uncom_diffs_filename,
        critical       => false,
        check_interval => 5,
        retry_interval => 5,
        retries        => 3,
        notes_url      => 'https://wikitech.wikimedia.org/wiki/Dbctl#Uncommitted_dbctl_diffs'
    }

    # Also set up a temporary check for diffs between db-{codfw,eqiad}.php and dbctl.
    $prod_vs_dbctl_filename = '/usr/local/lib/nagios/plugins/check_dbctl_deltas_from_mwconfig'

    file { $prod_vs_dbctl_filename:
        ensure => present,
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
        source => 'puppet:///modules/profile/conftool/check_dbctl_deltas_from_mwconfig.py'
    }

    nrpe::monitor_service { 'dbctl_deltas_from_mwconfig':
        ensure         => present,
        description    => "dbctl differs from mediawiki-config in ${::site}, did you forget to update both?",
        nrpe_command   => "${prod_vs_dbctl_filename} -d ${::site}",
        critical       => false,
        check_interval => 5,
        retry_interval => 5,
        retries        => 3,
        notes_url      => 'https://wikitech.wikimedia.org/wiki/Dbctl#Configuration_deltas_vs_PHP'
    }

}
