# == Class: haproxy
#
# === Parameters
#
# [*package_name*]
#   The package name used by package manager to install HAProxy in case of
#   variants (eg. haproxy-awslc).
#   Defaults to 'haproxy'
#
# [*logging*]
#   If set to true, logs will be saved to disk under /var/log/haproxy/haproxy.log.
#   It will work only if 'log /dev/log local0 info' is set. This implementation
#   will simply direct *all* haproxy logs.
#
#   Enabling this setting will also direct logs go logstash.wikimedia.org, making
#   them visible to all staff and NDAs.
#
# [*monitor*]
#   If set to false, monitoring will not be set up for icinga. Defaults to true.
#   Useful for places where monitoring is not appropriate or impossible via icinga
#   such as cloud or perhaps a PoC system
#
# [*monitor_check_haproxy*]
#   If set to false, monitoring based on icinga check_haproxy will be disabled.
#   This can be useful on certain environments where access to the HAProxy stats socket
#   needs to be as restricted as possible.
#
# [*logrotate_config*]
#   Override the logrotate config. If not provided, a default config file is used.
#
# [*systemd_override*]
#   Override system-provided unit. Defaults to false
#
# [*systemd_content*]
#   Content used to create the systemd::service. If not provided a default template
#   located on haproxy/haproxy.service.erb is used
#
# [*config_content*]
#   Content used to populate /etc/haproxy/haproxy.cfg. If not provided a default template
#   located on haproxy/haproxy.cfg.erb is used

class haproxy(
    $package_name                        = 'haproxy',
    $template                            = 'haproxy/haproxy.cfg.erb',
    $socket                              = '/run/haproxy/haproxy.sock',
    $pid                                 = '/run/haproxy/haproxy.pid',
    $monitor                             = true,
    $monitor_check_haproxy               = true,
    Boolean $logging                     = false,
    Stdlib::Filesource $logrotate_config = 'puppet:///modules/haproxy/haproxy.logrotate',
    Boolean $systemd_override            = false,
    Optional[String] $systemd_content    = undef,
    Optional[String] $config_content     = undef,
) {

    package { [
        'socat',
        $package_name,
    ]:
        ensure => present,
    }

    if $socket == '/run/haproxy/haproxy.sock' or $pid == '/run/haproxy/haproxy.pid' {
        systemd::tmpfile { 'haproxy':
            content => 'd /run/haproxy 0775 root haproxy',
        }
    }
    # /etc/haproxy is created by installing the haproxy package.
    # however manging ig in puppet means we can drop files into this directory
    # and not have to worry about dependencies as file objects get an auto require
    # for any managed parents directories
    file { ['/etc/haproxy', '/etc/haproxy/conf.d']:
        ensure => directory,
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
    }

    $haproxy_config_content = $config_content? {
        undef   => template($template),
        default => $config_content,
    }

    file { '/etc/haproxy/haproxy.cfg':
        ensure  => present,
        mode    => '0444',
        owner   => 'root',
        group   => 'root',
        content => $haproxy_config_content,
        notify  => Service['haproxy'],
    }

    # defaults file cannot be dynamic anymore on systemd
    # pregenerate them on systemd start/reload
    file { '/usr/local/bin/generate_haproxy_default.sh':
        ensure => absent,
    }

    file { '/etc/default/haproxy':
        ensure  => present,
        mode    => '0644',
        owner   => 'root',
        group   => 'root',
        content => template('haproxy/haproxy.default.erb'),
        notify  => Service['haproxy'],
    }

    $systemd_service_content = $systemd_content? {
        undef   => template('haproxy/haproxy.service.erb'),
        default => $systemd_content,
    }

    systemd::service { 'haproxy':
        override       => $systemd_override,
        content        => $systemd_service_content,
        service_params => {'restart' => '/bin/systemctl reload haproxy.service',}
    }

    nrpe::plugin { 'check_haproxy':
        ensure  => stdlib::ensure($monitor and $monitor_check_haproxy),
        content => template('haproxy/check_haproxy.erb'),
    }

    nrpe::monitor_service { 'haproxy':
        ensure         => stdlib::ensure($monitor),
        description    => 'haproxy process',
        nrpe_command   => '/usr/lib/nagios/plugins/check_procs -c 1: -C haproxy',
        notes_url      => 'https://wikitech.wikimedia.org/wiki/HAProxy',
        migration_task => 'T357099',
    }

    nrpe::monitor_service { 'haproxy_alive':
        ensure             => stdlib::ensure($monitor and $monitor_check_haproxy),
        description        => 'haproxy alive',
        nrpe_command       => '/usr/local/lib/nagios/plugins/check_haproxy --check=alive',
        notes_url          => 'https://wikitech.wikimedia.org/wiki/HAProxy',
        migration_task     => 'T407137',
        enable_nrpe2nodexp => true,
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
          source => $logrotate_config,
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
