# Profile class for recommendation_api
class profile::recommendation_api(
    String $wdqs_uri = hiera('profile::recommendation_api::wdqs_uri'),
    String $dbhost = hiera('profile::recommendation_api::dbhost'),
    String $dbname = hiera('profile::recommendation_api::dbname'),
    String $dbuser = hiera('profile::recommendation_api::dbuser'),
) {

    include passwords::recommendationapi::mysql
    $pwd = $::passwords::recommendationapi::mysql::recommendationapiservice_pass

    service::node { 'recommendation_api':
        port              => 9632,
        repo              => 'recommendation-api/deploy',
        healthcheck_url   => '',
        has_spec          => true,
        deployment        => 'scap3',
        deployment_config => true,
        deployment_vars   => {
            wdqs_uri => $wdqs_uri,
            dbhost   => $dbhost,
            dbname   => $dbname,
            dbuser   => $dbuser,
            dbpass   => $pwd,
        },
    }
}
