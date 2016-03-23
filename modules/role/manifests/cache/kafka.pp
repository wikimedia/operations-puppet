# == Class role::cache::kafka
# Base class for instances of varnishkafka on cache servers.
#
class role::cache::kafka {

    # APT pinning for Varnish 3
    if (hiera('varnish_version4', false)) {
        apt::pin { 'varnishkafka':
            ensure   => 'absent',
            pin      => '',
            priority => '',
        }
    } else {
        # Prefer varnishkafka 1.0.7, compatible with varnish 3
        apt::pin { 'varnishkafka':
            package  => 'varnishkafka*',
            pin      => 'version 1.0.7*',
            priority => 1002,
        }
    }

    # Make the Varnishkafka class depend on APT pinning. We want to ensure
    # varnishkafka is not apt-get installed before the pinning file is
    # created/removed.
    Apt::Pin['varnishkafka'] -> Class['Varnishkafka']

    # Make sure varnishes are configured and started for the first time
    # before the instances as well, or they fail to start initially...
    Service <| tag == 'varnish_instance' |> -> Varnishkafka::Instance <| |>
}
