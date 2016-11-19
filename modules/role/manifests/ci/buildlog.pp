# Jenkins console logs in ElasticSearch with Kibana
#
# http://ci-log.wmflabs.org/
#
# Configuration is done via Hiera
#
class role::ci::buildlog {
    system::role { 'role::ci::buildlog':
        description => 'CI build log (Kibana + ElasticSearch)'
    }

    require role::labs::lvm::srv

    include ::role::kibana
    include ::elasticsearch

    $elastic_search_data_dir = hiera('elasticsearch::data_dir')

    file { $elastic_search_data_dir:
        ensure  => directory,
        owner   => 'elasticsearch',
        group   => 'elasticsearch',
        require => Package['elasticsearch'],
        before  => Service['elasticsearch'],
    }
}
