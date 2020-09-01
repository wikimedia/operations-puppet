class nftables (
    Wmflib::Ensure             $ensure_package = 'present',
    Enum['stopped', 'running'] $ensure_service = 'stopped',
) {
    requires_os('debian >= buster')

    package { 'nftables':
        ensure => $ensure_package,
    }

    $nft_main_file = '/etc/nftables/main.nft' # used in the systemd template
    systemd::service { 'nftables':
        ensure         => $ensure_package,
        content        => systemd_template('nftables'),
        override       => true,
        service_params => {
            ensure => $ensure_service,
        }
    }

    # create a directory to hold the nftables config
    file { '/etc/nftables/':
        ensure => 'directory',
    }

    # deploy the basic configuration file, i.e, the basic nftables ruleset skeleton
    file { $nft_main_file:
        ensure  => $ensure_package,
        source  => 'puppet:///modules/nftables/main.nft',
        require => File['/etc/nftables'],
        notify  => Systemd::Service['nftables'],
    }

    # cleanup the file shipped with the debian package, we don't use it
    file { '/etc/nftables.conf':
        ensure => 'absent',
    }

    File <| tag == 'nft' |>
}
