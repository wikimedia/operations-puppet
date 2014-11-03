#TODO: this should probably go away. The cleanup scripts in puppet should do this by themselves.
define decommission_monitor_host {
    if defined(Nagios_host[$title]) {
        # Override the existing resources
        Nagios_host <| title == $title |> {
            ensure => absent
        }
        Nagios_hostextinfo <| title == $title |> {
            ensure => absent
        }
    }
    else {
        # Resources don't exist in Puppet. Remove from Nagios config as well.
        nagios_host { $title:
            host_name => $title,
            ensure    => absent;

        }
        nagios_hostextinfo { $title:
            host_name => $title,
            ensure    => absent;

        }
    }
}
