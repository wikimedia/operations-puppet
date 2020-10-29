# Class: profile::analytics::refinery::network_region_config
#
# Looks up Wikimedia network infrastructure configuration and
# renders a yaml mapping of (region -> [subnet1, subnet2, ...]).
#
class profile::analytics::refinery::network_region_config {

    # Get the list of infrastructure prefixes per site.
    include network::constants
    $network_infra = $::network::constants::network_infra

    # Render the config file.
    $network_region_config_file = "${::profile::analytics::refinery::config_dir}/network_region_config.yaml"
    file { $network_region_config_file:
        content => to_yaml($network_infra),
    }

}
