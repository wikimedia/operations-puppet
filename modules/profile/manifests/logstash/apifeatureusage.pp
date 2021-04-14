# vim:sw=4 ts=4 sts=4 et:
# == Class: profile::logstash::apifeatureusage
#
# Extension:ApiFeatureUsage into Elasticsearch.
#
# filtertags: labs-project-deployment-prep
class profile::logstash::apifeatureusage(
    Array[Stdlib::Host] $elastic_hosts   = lookup('profile::logstash::apifeatureusage::elastic_hosts'),
    Hash                $curator_actions = lookup('profile::logstash::apifeatureusage::curator_actions'),
) {
    include profile::logstash::collector

    # Template for Elasticsearch index creation
    # lint:ignore:puppet_url_without_modules
    file { '/etc/logstash/apifeatureusage-template.json':
        ensure => present,
        source => 'puppet:///modules/profile/logstash/apifeatureusage-template.json',
        owner  => 'root',
        group  => 'root',
        mode   => '0444',
    }
    # lint:endignore

    # Add configuration to logstash
    # Needs to come after 'filter_mediawiki' (priority 50)
    logstash::conf { 'filter_apifeatureusage':
        source   => 'puppet:///modules/profile/logstash/filter-apifeatureusage.conf',
        priority => 55,
    }

    $elastic_hosts.each |Stdlib::Host $host| {
        logstash::output::elasticsearch { "apifeatureusage-${host}":
            host            => $host,
            index           => 'apifeatureusage-%{+YYYY.MM.dd}',
            guard_condition => '[type] == "api-feature-usage-sanitized"',
            priority        => 95,
            template        => '/etc/logstash/apifeatureusage-template.json',
            require         => File['/etc/logstash/apifeatureusage-template.json'],
        }
    }

    # TODO: this curator config and job ought to run on the search cluster
    # It is here to maintain functionality until it can be moved
    $cluster_name = 'production-search-eqiad'
    $curator_hosts = $elastic_hosts
    $http_port = 9200

    elasticsearch::curator::config { $cluster_name:
        content => template('elasticsearch/curator_cluster.yaml.erb'),
    }

    elasticsearch::curator::job { 'apifeatureusage':
        ensure       => 'absent',
        cluster_name => $cluster_name,
    }
}
