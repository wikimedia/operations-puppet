# Nagios/icinga configuration files

class icinga::monitor::configuration::variables {

    # This variable declares the monitoring hosts It is called master hosts as
    # monitor_host is already a service.
    $master_hosts = [ 'neon.wikimedia.org' ]

    $icinga_config_dir = '/etc/icinga'
    $nagios_config_dir = '/etc/nagios'

    # puppet_hosts.cfg must be first
    $puppet_files = [
        "${icinga::monitor::configuration::variables::icinga_config_dir}/puppet_hostgroups.cfg",
        "${icinga::monitor::configuration::variables::icinga_config_dir}/puppet_servicegroups.cfg"]

    $static_files = [
        "${icinga::monitor::configuration::variables::icinga_config_dir}/puppet_hostextinfo.cfg",
        "${icinga::monitor::configuration::variables::icinga_config_dir}/puppet_services.cfg",
        "${icinga::monitor::configuration::variables::icinga_config_dir}/icinga.cfg",
        "${icinga::monitor::configuration::variables::icinga_config_dir}/analytics.cfg", # TEMP.  This will be removed when analytics puppetization goes to production
        "${icinga::monitor::configuration::variables::icinga_config_dir}/cgi.cfg",
        "${icinga::monitor::configuration::variables::icinga_config_dir}/checkcommands.cfg",
        "${icinga::monitor::configuration::variables::icinga_config_dir}/contactgroups.cfg",
        "${icinga::monitor::configuration::variables::icinga_config_dir}/contacts.cfg",
        "${icinga::monitor::configuration::variables::icinga_config_dir}/misccommands.cfg",
        "${icinga::monitor::configuration::variables::icinga_config_dir}/resource.cfg",
        "${icinga::monitor::configuration::variables::icinga_config_dir}/timeperiods.cfg"]
}

