# == Class: haproxy
#
# === Parameters
#
# [*logging*]
#   If set to true, logs will be saved to disk under /var/log/haproxy/haproxy.log.
#   It will work only if 'log /dev/log local0 info' is set. This implementation
#   will simply direct *all* haproxy logs.
#
# [*monitor*]
#   If set to false, monitoring will not be set up for icinga. Defaults to true.
#   Useful for places where monitoring is not appropriate or impossible via icinga
#   such as cloud or perhaps a PoC system
#

class haproxy(
    $template = 'haproxy/haproxy.cfg.erb',
    $socket   = '/run/haproxy/haproxy.sock',
    $pid      = '/run/haproxy/haproxy.pid',
    $monitor  = true,
    $logging  = false,
) {

    package { [
        'socat',
        'haproxy',
    ]:
        ensure => present,
    }

    # FIXME: Migrate to systemd::tmpfile
    if $socket == '/run/haproxy/haproxy.sock' or $pid == '/run/haproxy/haproxy.pid' {
        file { '/run/haproxy':
            ensure => directory,
            mode   => '0775',
            owner  => 'root',
            group  => 'haproxy',
        }
    }

    file { '/etc/haproxy/conf.d':
        ensure => directory,
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
    }

    file { '/etc/haproxy/haproxy.cfg':
        ensure  => present,
        mode    => '0444',
        owner   => 'root',
        group   => 'root',
        content => template($template),
        notify  => Exec['restart-haproxy']
    }

    exec { 'restart-haproxy':
        command     => '/bin/systemctl restart haproxy',
        refreshonly => true,
    }

    # defaults file cannot be dynamic anymore on systemd
    # pregenerate them on systemd start/reload
    file { '/usr/local/bin/generate_haproxy_default.sh':
        ensure => present,
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
        source => 'puppet:///modules/haproxy/generate_haproxy_default.sh',
    }

    # TODO: this should use the general systemd puppet abstraction instead
    file { '/lib/systemd/system/haproxy.service':
        ensure  => present,
        mode    => '0644',
        owner   => 'root',
        group   => 'root',
        content => template('haproxy/haproxy.service.erb'),
        require => File['/usr/local/bin/generate_haproxy_default.sh'],
        notify  => Exec['/bin/systemctl daemon-reload'],
    }

    exec { '/bin/systemctl daemon-reload':
        user        => 'root',
        refreshonly => true,
    }

    if $monitor {
        file { '/usr/lib/nagios/plugins/check_haproxy':
            owner   => 'root',
            group   => 'root',
            mode    => '0755',
            content => template('haproxy/check_haproxy.erb'),
        }

        nrpe::monitor_service { 'haproxy':
            description  => 'haproxy process',
            nrpe_command => '/usr/lib/nagios/plugins/check_procs -c 1: -C haproxy',
            notes_url    => 'https://wikitech.wikimedia.org/wiki/HAProxy',
        }

        nrpe::monitor_service { 'haproxy_alive':
            description  => 'haproxy alive',
            nrpe_command => '/usr/lib/nagios/plugins/check_haproxy --check=alive',
            notes_url    => 'https://wikitech.wikimedia.org/wiki/HAProxy',
        }
    }

    if $logging {
        file { '/var/log/haproxy':
          ensure => directory,
          owner  => 'root',
          group  => 'adm',
          mode   => '0750',
        }

        logrotate::conf { 'haproxy':
          ensure => present,
          source => 'puppet:///modules/haproxy/haproxy.logrotate',
        }

        rsyslog::conf { 'haproxy':
          source   => 'puppet:///modules/haproxy/haproxy.rsyslog',
          priority => 49,
          require  => File['/var/log/haproxy'],
        }

        # The debian package originaly will cause the creation
        # of this file, it will be simply confusing if it remains there
        file { '/var/log/haproxy.log':
          ensure => absent,
        }

    }

}
