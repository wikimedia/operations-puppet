# == Class: elasticsearch::packages
#
# Provisions Elasticsearch package and dependencies.
#
class elasticsearch::packages (
    String $package_name,
    String $apt_component,
    Boolean $send_logs_to_logstash,
) {
    include ::java::tools

    # library for elasticsearch
    ensure_packages(['python3-elasticsearch'])

    apt::package_from_component { 'elasticsearch-oss':
        component => "component/${apt_component} thirdparty/${apt_component}",
    }

    ### install and link additional log4j appender to send logs over GELF

    # we only require the packages, we do not remove them as there might be
    # other dependencies
    if $send_logs_to_logstash {
        ensure_packages('liblogstash-gelf-java')
        ensure_packages('libjson-simple-java')
    }

    # symlinks are removed if log shipping is disabled
    file { '/usr/share/elasticsearch/lib/logstash-gelf.jar':
        ensure  => stdlib::ensure($send_logs_to_logstash, 'link'),
        target  => '/usr/share/java/logstash-gelf.jar',
        require => 'Package[elasticsearch-oss]',
    }
    file { '/usr/share/elasticsearch/lib/json-simple.jar':
        ensure  => stdlib::ensure($send_logs_to_logstash, 'link'),
        target  => '/usr/share/java/json-simple.jar',
        require => 'Package[elasticsearch-oss]',
    }

}
