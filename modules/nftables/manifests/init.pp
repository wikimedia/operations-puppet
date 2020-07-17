class nftables (
    Wmflib::Ensure             $ensure_package = 'present',
    Enum['stopped', 'running'] $ensure_service = 'stopped',
) {
    requires_os('debian >= buster')

    package { 'nftables':
        ensure => $ensure_package,
    }

    service { 'nftables':
        ensure => $ensure_service,
    }
}
