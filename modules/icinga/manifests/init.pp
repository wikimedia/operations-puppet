class icinga (
    $site_name,
) {

    @monitor_group { 'misc_eqiad': description => 'eqiad misc servers' }
    @monitor_group { 'misc_pmtpa': description => 'pmtpa misc servers' }
    # This needs to be consolited in the virt cluster probably
    @monitor_group { 'labsnfs_eqiad': description => 'eqiad labsnfs server servers' }

    include facilities::pdu_monitoring
    include icinga::ganglia_check
    include icinga::ganglios
    include icinga::apache
    include icinga::check_paging
    include icinga::config_files
    include icinga::misc_files
    include icinga::plugins
    include icinga::firewall
    include icinga::logrotate
    include icinga::naggen
    include icinga::nsca_daemon
    include icinga::packages
    include icinga::service
    include icinga::snmp
    include icinga::user
    include lvs::monitor
    include misc::dsh::files
    include mysql
    include nagios::gsbmonitoring
    include nrpe
    include passwords::nagios::mysql

    Class['icinga::packages'] -> Class['icinga::config_files'] -> Class['icinga::service']

}

