# vim:sw=4 ts=4 sts=4 et:
# == Class: role::logstash::puppetreports
#
# Set up a TCP listener to listen for puppet failure reports.
#
# filtertags: labs-project-deployment-prep
class role::logstash::puppetreports {
    require ::role::logstash::collector

    if $::realm != 'labs' {
        # Constrain to only labs, security issues in prod have not been worked out yet
        fail('role::logstash::puppetreports may only be deployed to Labs.')
    }

    logstash::input::tcp { 'tcp_json':
        port  => 5229,
        codec => 'json_lines',
    }

    ferm::service { 'logstash_tcp_json':
        proto  => 'tcp',
        port   => '5229',
        srange => '$DOMAIN_NETWORKS',
    }

    # lint:ignore:puppet_url_without_modules
    logstash::conf { 'filter_puppet':
        source   => 'puppet:///modules/role/logstash/filter-puppet.conf',
        priority => 50,
    }
    # lint:endignore
}
