# vim: set ts=4 et sw=4:
#
# filtertags: labs-project-deployment-prep

class profile::cxserver(
    $apertium_uri=hiera('profile::cxserver::apertium_uri')
) {
    include ::passwords::cxserver
    $lingocloud_api_key = $::passwords::cxserver::lingocloud_api_key
    $matxin_api_key     = $::passwords::cxserver::matxin_api_key
    $yandex_api_key     = $::passwords::cxserver::yandex_api_key
    $youdao_api_key     = $::passwords::cxserver::youdao_api_key
    $jwt_secret         = $::passwords::cxserver::jwt_secret

    service::node { 'cxserver':
        port              => 8080,
        healthcheck_url   => '',
        has_spec          => true,
        deployment        => 'scap3',
        deployment_config => true,
        deployment_vars   => {
            jwt_token          => $jwt_secret,
            apertium_uri       => $apertium_uri,
            lingocloud_key     => $lingocloud_api_key,
            lingocloud_account => 'wikimedia',
            matxin_key         => $matxin_api_key,
            yandex_key         => $yandex_api_key,
            youdao_key         => $youdao_api_key,
        },
    }
}
