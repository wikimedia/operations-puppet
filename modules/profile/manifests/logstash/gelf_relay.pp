# SPDX-License-Identifier: Apache-2.0
# vim:sw=4 ts=4 sts=4 et:
# == Class: profile::logstash::gelf_relay
#
# A minimal Logstash instance to ingest GELF formatted logs on localhost and output to syslog
#
# Logs flow like this:
#
# GELF log producer -> logstash (localhost:12201/UDP) -> rsyslog (localhost:11514/UDP) -> kafka-logging
#
class profile::logstash::gelf_relay (
) {

    contain profile::java

    # run a lightweight logstash instance
    class { 'logstash':
        logstash_package => 'logstash-oss',
        logstash_version => 6,
        pipeline_workers => 2,
        log_format       => 'json',
        java_package     => $profile::java::default_package_name,
    }

    # Clean up old logstash package name - T297468
    package { 'logstash-old-name':
        ensure => absent,
        name   => 'logstash',
        before => Package['logstash']
    }

    # Logstash listens on localhost:12201/UDP for GELF formatted logs
    logstash::input::gelf { 'gelf_relay':
        host => 'localhost',
        port => '12201',
        tags => ['input-gelf-relay'],
    }

    # Logstash outputs json formatted logs to rsyslog listener on localhost:11514/UDP
    # note: rsyslog 11514 udp listener config is provided by profile::rsyslog::udp_json_logback_compat
    logstash::output::udp { 'gelf_relay':
        host  => 'localhost',
        port  => '11514',
        codec => 'json',
    }

}
