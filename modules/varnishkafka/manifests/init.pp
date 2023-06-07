# SPDX-License-Identifier: Apache-2.0
# == Class varnishkafka
# Configures and runs varnishkafka Varnish to Kafka producer.
# See: https://github.com/wikimedia/varnishkafka
#
class varnishkafka {
    package { 'varnishkafka':
        ensure => present,
    }

    file { '/etc/varnishkafka':
        ensure  => directory,
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        recurse => true,
        purge   => true,
        force   => true,
    }

    # Don't use the init script provided by the package, because it precludes
    # running multiple instances.

    file { '/var/cache/varnishkafka':
        ensure  => directory,
        owner   => 'varnishlog',
        group   => 'varnish',
        mode    => '0755',
        require => Package['varnishkafka'],
    }

    # Basic rsyslog.d configuration to create /var/log/varnishkafka.log
    if defined(Service['rsyslog']) {
        file { '/etc/rsyslog.d/70-varnishkafka.conf':
            owner  => 'root',
            group  => 'root',
            mode   => '0444',
            source => 'puppet:///modules/varnishkafka/varnishkafka_rsyslog.conf',
            notify =>  Service['rsyslog']
        }
    }

    # Since we are doing per instance stats.json files, the logrotate
    # config that comes with the varnishkafka instance is not sufficient.
    # This file will rotate only the daemon log file at /var/log/varnishkafka.log
    # varnishkafka::instance will take care of installing a logrotate file for
    # the per-instance stats.json file.
    file { '/etc/logrotate.d/varnishkafka':
        owner  => 'root',
        group  => 'root',
        mode   => '0444',
        source => 'puppet:///modules/varnishkafka/varnishkafka_logrotate'
    }

    # Managing the varnishkafka service via its init script requires that the
    # init script be present and that the default file mark the service as
    # enabled. Invoking start-stop-daemon directly allows us to manage the
    # service without having a tricky ordering dependency on those two
    # resources.

    exec { 'stop-varnishkafka-service':
        command   => '/sbin/start-stop-daemon --stop --pidfile /var/run/varnishkafka/varnishkafka.pid --exec /usr/bin/varnishkafka',
        onlyif    => '/sbin/start-stop-daemon --status --pidfile /var/run/varnishkafka/varnishkafka.pid --exec /usr/bin/varnishkafka',
        subscribe => Package['varnishkafka'],
    }

    file { '/etc/init.d/varnishkafka':
        ensure    => absent,
        subscribe => Package['varnishkafka'],
    }

    file { '/etc/default/varnishkafka':
        ensure    => absent,
        subscribe => Package['varnishkafka'],
    }
}
