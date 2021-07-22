# @summary create a function to prevent services from autostarting on installation
# @param service the name of the service
# @param enabled boolean indicating if the service autostart should be enabled.
function debian::autostart (
    String  $service,
    Boolean $enabled,
) {
    # For Debian Bullseye and later we use the systemd-native preset feature.
    # This doesn't work in Buster and older, so on those distros we fall back
    # to update-rc.d
    if debian::codename::ge('bullseye') {

        file { "/etc/systemd/system-preset/${service}.preset":
            ensure  => stdlib::ensure(!$enabled, 'file'),
            owner   => 'root',
            group   => 'root',
            mode    => '0444',
            content => "disable ${service}.service",
        }

    } else {
        include debian::policy_rc_d
        file { "${debian::policy_rc_d::policy_rd_d_dir}/${service}":
            ensure => stdlib::ensure(!$enabled, 'file'),
            owner  => 'root',
            group  => 'root',
            mode   => '0444',
        }
    }
}
