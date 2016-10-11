#TODO: this should probably go away.
# The cleanup scripts in puppet should do this by themselves.
define monitoring::decommission_monitor_host {
    if defined(Nagios_host[$title]) {
        # Override the existing resources
        Nagios_host <| title == $title |> {
            ensure => absent
        }
    }
    else {
        # Resources don't exist in Puppet. Remove from Nagios config as well.
        nagios_host { $title:
            ensure    => absent,
            host_name => $title,

        }
    }
}
