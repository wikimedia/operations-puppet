class role::mediawiki::scaler {
    include ::role::mediawiki::common
    include ::mediawiki::multimedia

    file { '/etc/wikimedia-scaler':
        ensure => present,
        owner  => 'root',
        group  => 'root',
        mode   => '0444',
    }

    # monitor orphaned HHVM threads/requests that are no longer in apache
    # see https://phabricator.wikimedia.org/T153488
    file { '/usr/local/lib/nagios/plugins/check_leaked_hhvm_threads':
        ensure => present,
        source => 'puppet:///modules/role/mediawiki/check_leaked_hhvm_threads.py',
        mode   => '0555',
        owner  => 'root',
        group  => 'root',
    }

    nrpe::monitor_service { 'check_leaked_hhvm_threads':
        description  => 'Check HHVM threads for leakage',
        nrpe_command => '/usr/local/lib/nagios/plugins/check_leaked_hhvm_threads',
        require      => File['/usr/local/lib/nagios/plugins/check_leaked_hhvm_threads'],
    }
}
