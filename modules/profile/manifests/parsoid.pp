class profile::parsoid(
    Boolean $has_lvs = hiera('has_lvs', true),
    Integer[1025, 65535] $port = lookup('profile::parsoid::port', {'default_value' => 8000}),
) {
    if $has_lvs {
        require ::profile::lvs::realserver
    }

    class { '::service::configuration': }

    $mwapi_server = "${::service::configuration::mwapi_host}/w/api.php"
    class { '::parsoid':
        port         => $port,
        mwapi_server => $mwapi_server,
        mwapi_proxy  => ''
    }
}
