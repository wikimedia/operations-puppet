class icinga::monitor {

    include facilities::pdu_monitoring
    include icinga::ganglia::check
    include icinga::ganglia::ganglios
    include icinga::monitor::apache
    include icinga::monitor::checkpaging
    include icinga::monitor::configuration::files
    include icinga::monitor::files::misc
    include icinga::monitor::files::nagios-plugins
    include icinga::monitor::firewall
    include icinga::monitor::logrotate
    include icinga::monitor::naggen
    include icinga::monitor::nsca::daemon
    include icinga::monitor::packages
    include icinga::monitor::service
    include icinga::monitor::snmp
    include icinga::user
    include lvs::monitor
    include misc::dsh::files
    include mysql
    include nagios::gsbmonitoring
    include nrpe
    include passwords::nagios::mysql

    Class['icinga::monitor::packages'] -> Class['icinga::monitor::configuration::files'] -> Class['icinga::monitor::service']

}

