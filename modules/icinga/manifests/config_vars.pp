# Nagios/icinga configuration files

class icinga::config_vars {

    # This variable declares the monitoring hosts It is called master hosts as
    # monitor_host is already a service.
    $master_hosts = [ 'neon.wikimedia.org' ]

    $icinga_config_dir = '/etc/icinga'
    $nagios_config_dir = '/etc/nagios'

    # puppet_hosts.cfg must be first
    $puppet_files = [
        "${icinga::config_vars::icinga_config_dir}/puppet_hostgroups.cfg",
        "${icinga::config_vars::icinga_config_dir}/puppet_servicegroups.cfg"]

    $static_files = [
        "${icinga::config_vars::icinga_config_dir}/puppet_hostextinfo.cfg",
        "${icinga::config_vars::icinga_config_dir}/puppet_services.cfg",
        "${icinga::config_vars::icinga_config_dir}/icinga.cfg",
        "${icinga::config_vars::icinga_config_dir}/analytics.cfg", # TEMP.  This will be removed when analytics puppetization goes to production
        "${icinga::config_vars::icinga_config_dir}/cgi.cfg",
        "${icinga::config_vars::icinga_config_dir}/checkcommands.cfg",
        "${icinga::config_vars::icinga_config_dir}/contactgroups.cfg",
        "${icinga::config_vars::icinga_config_dir}/contacts.cfg",
        "${icinga::config_vars::icinga_config_dir}/misccommands.cfg",
        "${icinga::config_vars::icinga_config_dir}/resource.cfg",
        "${icinga::config_vars::icinga_config_dir}/timeperiods.cfg"]
}

