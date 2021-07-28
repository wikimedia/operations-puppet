# @summary Add/Remove systemd presets
# The following semantics apply:
# - It prevents the start of the service after installation
# - It allows a manual start of the service with "systemctl start foo"
# - It also prevents the start of the service on boot
#
# @param ensure ensurable parameter
# @param service The name of the service to act on
define systemd::preset (
    Wmflib::Ensure $ensure  = 'present',
    String[1]      $service = $title,
) {
    debian::codename::require::min('bullseye')

    ensure_resource('file', '/etc/systemd/system-preset', {
        ensure => 'directory',
        owner  => 'root',
        group  => 'root',
        mode   => '0444',
    })
    ensure_resource('file', "/run/wikimedia/systemd-preset/${service}.preset", {
        ensure  => stdlib::ensure($ensure, 'file'),
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        content => "disable ${service}.service",
    })
}
