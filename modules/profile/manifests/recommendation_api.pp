# Profile class for recommendation_api
class profile::recommendation_api(
    Stdlib::Httpurl $wdqs_uri = lookup('profile::recommendation_api::wdqs_uri'),
    Stdlib::Host $dbhost      = lookup('profile::recommendation_api::dbhost'),
    String $dbname            = lookup('profile::recommendation_api::dbname'),
    String $dbuser            = lookup('profile::recommendation_api::dbuser'),
){

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
