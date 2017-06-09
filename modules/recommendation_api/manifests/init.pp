# == Class: recommendation_api
#
# The Wikimedia Recommendation API is an API that provides personalized
# recommendations of wiki content (to discover, edit, translate, etc.).
# It is a webapp based on ServiceTemplateNode
#
# See <https://meta.wikimedia.org/wiki/Recommendation_API> for more info.
#
# === Parameters
#
# [*wdqs_uri*]
#   The full URI of the WDQS API endpoint to contact when issuing direct
#   requests to it.
#
class recommendation_api(
    $wdqs_uri = 'http://wdqs.svc.eqiad.wmnet:????',
) {
    include ::service::configuration

    service::node { 'recommendation-api':
        port              => 1970,
        healthcheck_url   => '',
        has_spec          => true,
        deployment        => 'scap3',
        deployment_config => true,
        deployment_vars   => {
            mwapi_uri    => $::service::configuration::mwapi_uri,
            restbase_uri => $::service::configuration::restbase_uri,
            wdqs_uri     => $wdqs_uri,
        },
    }
}

