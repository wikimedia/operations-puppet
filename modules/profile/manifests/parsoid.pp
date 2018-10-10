class profile::parsoid(
    Boolean $has_lvs = hiera('has_lvs', true),
) {
    if $has_lvs {
        require ::profile::lvs::realserver
    }

    class { '::service::configuration': }

    $mwapi_server = "${::service::configuration::mwapi_host}/w/api.php"
    class { '::parsoid':
        port         => 8000,
        mwapi_server => $mwapi_server,
        mwapi_proxy  => ''
    }
}
