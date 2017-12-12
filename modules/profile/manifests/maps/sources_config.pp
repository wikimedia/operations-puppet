# Define: profile::maps::sources_config
#
# Deploy a configuration of sources for kartotherian / tilerator
#
# Parameters:
#   mode
#       Use either kartotherian or tilerator mode (config is slightly different for each).
#  style
#       The style to use to render tiles
define profile::maps::sources_config (
    $storage_id,
    $ensure = 'present',
    $mode   = 'kartotherian',
    $style  = 'osm-bright-style',
) {
    if ! $mode in ['kartotherian', 'tilerator'] {
        fail("mode shoudl be either kartotherian or tilerator but was ${mode}")
    }

    file { "/etc/${title}/sources.yaml":
        ensure  => $ensure,
        content => template('profile/maps/sources.yaml.erb'),
        owner   => 'root',
        group   => 'root',
        mode    => '0644',
    }
}
