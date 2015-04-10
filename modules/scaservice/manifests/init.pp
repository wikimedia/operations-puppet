# == Class: scaservice
#
# scaservice provides a common wrapper for setting up Node.js services
# based on service-template-node on the SCA cluster. Note that most of
# the facts listed as parameters to this class are set correctly via
# Hiera. The only required parameter is the port. Alternatively, config
# may be given as well if needed.
#
# === Parameters
#
# [*port*]
#   Port on which to run the service
#
# [*config*]
#   The individual service's config to use. It can be eaither a hash of
#   key => value pairs, or a YAML-formatted string. Note that the complete
#   configuration will be assembled using the bits given here and common
#   SCA service configuration directives
#
# [*http_proxy*]
#   Full URL of the proxy to use
#
# [*statsd_host*]
#   StatsD host. Optional. Default: localhost
#
# [*statsd_port*]
#   StatsD port. Default: 8125
#
# [*logstash_host*]
#   GELF logging host. Default: localhost
#
# [*logstash_port*]
#   GELF logging port. Default: 12201
#
# [*local_logdir*]
#   Local root log directory. The service's logs will be placed in its
#   subdirectory. Default: /var/log
#
# [*no_file*]
#   Number of maximum allowed open files for the service, to be set by
#   ulimit. Default: 10000
#
# === Examples
#
# To set up a service named myservice on port 8520 and with a templated
# configuration, use:
#
#    scaservice { 'myservice':
#        port   => 8520,
#        config => template('myservice/config.yaml.erb'),
#    }
#
# Likewise, you can supply the configuration directly as a hash:
#
#    scaservice {
#        port   => 8520,
#        config => {
#            param1 => 'val1',
#            param2 => $myvar
#        },
#    }
#
class scaservice(
    $port          = undef,
    $config        = {},
    $http_proxy    = undef,
    $statsd_host   = 'localhost',
    $statsd_port   = 8125,
    $logstash_host = 'localhost',
    $logstash_port = 12201,
    $local_logdir  = '/var/log',
    $no_file       = 10000,
) {

    # we do not allow empty names
    unless $title and size($title) > 0 {
        fail('No name for this resource given!')
    }

    # sanity check since a default port cannot be assigned
    unless $port and $port =~ /^\d+$/ {
        fail('Service port must be specified and must be a number!')
    }

    # the local log file name
    $local_logfile = "${local_logdir}/${title}/main.log"

    # assemble the config hash
    $full_config = merge_config(
        template("${module_name}/config.yaml.erb"),
        $config
    )

    require_package('nodejs', 'nodejs-legacy')

    package { "${title}/deploy":
        provider => 'trebuchet',
    }

    group { $title:
        ensure => present,
        name   => $title,
        system => true,
    }

    user { $title:
        gid    => $title,
        home   => '/nonexistent',
        shell  => '/bin/false',
        system => true,
        before => Service[$title],
    }

    file { "/etc/${title}":
        ensure => directory,
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
    }

    file { "/etc/${title}/config.yaml":
        ensure  => present,
        content => inline_template(
            '<%= YAML.dump(@full_config).sub(/^-+\s/, "") %>'
        ),
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        require => [
            Package["${title}/deploy"],
            File["/etc/${title}"],
        ],
        notify  => Service[$title],
    }

    file { $local_logdir:
        ensure => directory,
        owner  => $title,
        group  => $title,
        mode   => '0775',
        before => Service[$title],
    }

    file { "/etc/init/${title}.conf":
        content => template("${module_name}/upstart.conf.erb"),
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        notify  => Service[$title],
    }

    file { "/etc/logrotate.d/${title}":
        content => template("${module_name}/logrotate.erb"),
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
    }

    service { $title:
        ensure     => running,
        hasstatus  => true,
        hasrestart => true,
        provider   => 'upstart',
        require    => Package['nodejs', "${title}/deploy"],
    }

}
