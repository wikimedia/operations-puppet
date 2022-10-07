# SPDX-License-Identifier: Apache-2.0
# vim:sw=4 ts=4 sts=4 et:
# == Class: profile::logstash::apifeatureusage
#
# Extension:ApiFeatureUsage into Elasticsearch.
#
class profile::logstash::apifeatureusage(
    Array[Stdlib::Host]    $targets         = lookup('profile::logstash::apifeatureusage::targets'),
    Hash                   $curator_actions = lookup('profile::logstash::apifeatureusage::curator_actions'),
    Optional[Stdlib::Fqdn] $jobs_host       = lookup('profile::logstash::apifeatureusage::jobs_host', { default_value => undef }),
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

    $targets.each |Stdlib::Host $cluster| {
        logstash::output::elasticsearch { "apifeatureusage-${cluster}":
            host            => $cluster,
            index           => 'apifeatureusage-%{+YYYY.MM.dd}',
            guard_condition => '[type] == "api-feature-usage-sanitized"',
            priority        => 95,
            template        => '/etc/logstash/apifeatureusage-template.json',
            require         => File['/etc/logstash/apifeatureusage-template.json'],
        }

        # TODO: this curator config and job ought to run on the search cluster
        # It is here to maintain functionality until it can be moved
        $dc = $cluster.split('[.]')[-2]
        $cluster_name = "production-search-${dc}"
        $curator_hosts = [$cluster]
        $http_port = 9200
        if $jobs_host == $::fqdn {
            elasticsearch::curator::config { $cluster_name:
                content => template('elasticsearch/curator_cluster.yaml.erb'),
            }

            elasticsearch::curator::job { "apifeatureusage_${dc}":
                cluster_name => $cluster_name,
                actions      => $curator_actions,
            }
        } else {
            elasticsearch::curator::job { "apifeatureusage_${dc}":
                ensure       => 'absent',
                cluster_name => $cluster_name,
            }
        }
    }
}
