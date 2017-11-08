# vim:sw=4 ts=4 sts=4 et:
# == Class: role::logstash::apifeatureusage
#
# Builds on role::logstash to insert sanitized data for
# Extension:ApiFeatureUsage into Elasticsearch.
#
# filtertags: labs-project-deployment-prep
class profile::logstash::apifeatureusage(
    $hosts = hiera('role::logstash::apifeatureusage::elastic_hosts'),
) {

    validate_array($hosts)

    # Template for Elasticsearch index creation
    file { '/etc/logstash/apifeatureusage-template.json':
        ensure => present,
        source => 'puppet:///modules/profile/logstash/apifeatureusage-template.json',
        owner  => 'root',
        group  => 'root',
        mode   => '0444',
    }

    # Add configuration to logstash
    # Needs to come after 'filter_mediawiki' (priority 50)
    logstash::conf { 'filter_apifeatureusage':
        source   => 'puppet:///modules/profile/logstash/filter-apifeatureusage.conf',
        priority => 55,
    }

    # Output destined for separate Elasticsearch cluster from Logstash cluster
    profile::logstash::apifeatureusage::elasticsearch { $hosts: }

}
