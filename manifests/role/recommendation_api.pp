# == Class: role::recommendation_api
#
# Provisions a JSON API for personalized recommendations.
#
class role::recommendation_api {
    include ::recommendation_api

    include ::apache::mod::uwsgi

    apache::site { 'recommendation_api':
        content => template('role/apache/sites/recommendation_api.erb'),
    }

    ferm::service { 'recommendation_api_http':
        proto => 'tcp',
        port  => '80',
    }
}
