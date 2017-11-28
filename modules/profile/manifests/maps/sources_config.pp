# Define: profile::maps::sources_config
#
# Deploy a configuration of sources for kartotherian / tilerator
#
# Parameters:
#   mode
#       Use either kartotherian or tilerator mode (config is slightly different for each).
define profile::maps::sources_config (
    $storage_id,
    $ensure = 'present',
    $mode   = 'kartotherian',
) {
    if ! $mode in ['kartotherian', 'tilerator'] {
        fail("mode shoudl be either kartotherian or tilerator but was ${mode}")
    }

    $loader = $mode ? {
        'tilerator' => '\'@kartotherian/osm-bright-style\'',
        default     => 'osm-bright-style'
    }

    file { "/etc/${title}/sources.yaml":
        ensure  => $ensure,
        content => template('profile/maps/sources.yaml.erb'),
        owner   => 'root',
        group   => 'root',
        mode    => '0644',
    }
}
