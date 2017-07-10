# Profile class for recommendation_api
class profile::recommendation_api($wdqs_uri=hiera('profile::recommendation_api::wdqs_uri')) {

    service::node { 'recommendation_api':
        port              => 9632,
        repo              => 'recommendation-api/deploy',
        healthcheck_url   => '',
        has_spec          => true,
        deployment        => 'scap3',
        deployment_config => true,
        deployment_vars   => {
            wdqs_uri => $wdqs_uri,
        },
    }
}
