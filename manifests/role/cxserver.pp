# vim: set ts=4 et sw=4:

class role::cxserver {
    system::role { 'role::cxserver':
        description => 'content translation server'
    }
    # LVS pooling/depoling scripts
    include ::lvs::configuration
    conftool::scripts::service { 'cxserver':
        lvs_services_config => $::lvs::configuration::lvs_services,
        lvs_class_hosts     => $::lvs::configuration::lvs_class_hosts,
    }

    include ::passwords::cxserver
    $yandex_api_key = $::passwords::cxserver::yandex_api_key
    $youdao_api_key = $::passwords::cxserver::youdao_api_key
    $jwt_secret = $::passwords::cxserver::jwt_secret

    class { '::cxserver':
        yandex_api_key => $yandex_api_key,
        youdao_api_key => $youdao_api_key,
        jwt_secret     => $jwt_secret,
    }
}
