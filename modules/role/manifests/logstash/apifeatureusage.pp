# vim:sw=4 ts=4 sts=4 et:
# == Class: role::logstash::apifeatureusage
#
# Builds on role::logstash to insert sanitized data for
# Extension:ApiFeatureUsage into Elasticsearch.
#
# filtertags: labs-project-deployment-prep
class role::logstash::apifeatureusage {
    include ::role::logstash::collector

    # FIXME: make this a param and use hiera to vary by realm
    $host            = $::realm ? {
        'production' => '10.2.2.30', # search.svc.eqiad.wmnet
        'labs'       => 'deployment-elastic05', # Pick one at random
    }

    # Template for Elasticsearch index creation
    # lint:ignore:puppet_url_without_modules
    file { '/etc/logstash/apifeatureusage-template.json':
        ensure => present,
        source => 'puppet:///modules/role/logstash/apifeatureusage-template.json',
        owner  => 'root',
        group  => 'root',
        mode   => '0444',
    }

    # Add configuration to logstash
    # Needs to come after 'filter_mediawiki' (priority 50)
    logstash::conf { 'filter_apifeatureusage':
        source   => 'puppet:///modules/role/logstash/filter-apifeatureusage.conf',
        priority => 55,
        require  => Logstash::Plugin['logstash-filter-prune'],
    }
    # lint:endignore

    # Output destined for separate Elasticsearch cluster from Logstash cluster
    logstash::output::elasticsearch { 'apifeatureusage':
        host            => $host,
        guard_condition => '[type] == "api-feature-usage-sanitized"',
        manage_indices  => true,
        priority        => 95,
        template        => '/etc/logstash/apifeatureusage-template.json',
        require         => File['/etc/logstash/apifeatureusage-template.json'],
    }
}
