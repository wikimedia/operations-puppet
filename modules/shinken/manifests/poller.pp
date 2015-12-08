# Class: shinken::poller
#
# Install, configure and ensure running for shinken poller daemon
#
# Parameters:
#   $poller_name
#       Name of the daemon. Defaults to fqdn
#   $listen_address
#       The address this daemon should be listening on
class shinken::poller(
    $poller_name    = $::fqdn,
    $listen_address = $::ipaddress,
) {
    # TODO: Possibly move this into monitoring module and include at the role
    # level
    $plugin_packages = [
        'monitoring-plugins',
        'nagios-nrpe-plugin',
        'monitoring-plugins-basic',
        'monitoring-plugins-common',
        'monitoring-plugins-standard',
    ]
    ensure_packages($plugin_packages)

    shinken::daemon { "poller-${poller_name}":
        daemon         => 'poller',
        port           => 7771,
        listen_address => $listen_address,
        conf_file      => '/etc/shinken/daemons/pollerd.ini',
    }
}
