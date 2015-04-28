# == Define: service::node
#
# service::node provides a common wrapper for setting up Node.js services
# based on service-template-node on. Note that most of
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
#   node service configuration directives. If none is provided, we
#   assume the config  can be built from a template in a standard location
#
# [*no_file*]
#   Number of maximum allowed open files for the service, to be set by
#   ulimit. Default: 10000
#
# [*healthcheck_url*]
#   The url to monitor the service at. 200 OK is the expected answer
#
# === Examples
#
# To set up a service named myservice on port 8520 and with a templated
# configuration, use:
#
#    service::node { 'myservice':
#        port   => 8520,
#        config => template('myservice/config.yaml.erb'),
#    }
#
# Likewise, you can supply the configuration directly as a hash:
#
#    service::node { 'myservice':
#        port   => 8520,
#        config => {
#            param1 => 'val1',
#            param2 => $myvar
#        },
#    }
#
define service::node( $port,
                      $config = undef,
                      $no_file = 10000,
                      $healthcheck_url='/_info',
) {
    # Import all common configuration
    include service::configuration

    # load configuration; if none is provided, assume it's
    # in a standard location
    $local_config = $config ? {
        undef   => template("service/node/${title}_config.yaml.erb"),
        default => $config,
    }

    # we do not allow empty names
    unless $title and size($title) > 0 {
        fail('No name for this resource given!')
    }

    # sanity check since a default port cannot be assigned
    unless $port and $port =~ /^\d+$/ {
        fail('Service port must be specified and must be a number!')
    }

    # the local log file name
    $local_logdir = "${service::configuration::log_dir}/${title}"
    $local_logfile = "${local_logdir}/main.log"

    # Software and the deployed code
    require_package('nodejs', 'nodejs-legacy')
    package { "${title}/deploy":
        provider => 'trebuchet',
    }

    # User/group
    group { $title:
        ensure => present,
        name   => $title,
        system => true,
        before => Service[$title],
    }

    user { $title:
        gid    => $title,
        home   => undef,
        shell  => '/bin/false',
        system => true,
        before => Service[$title],
    }

    # Configuration, directories
    file { "/etc/${title}":
        ensure => directory,
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
    }

    file { "/etc/${title}/config.yaml":
        ensure  => present,
        content => merge_config(
            template('service/node/config.yaml.erb'),
            $local_config
            ),
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        notify  => Service[$title],
    }

    file { $local_logdir:
        ensure => directory,
        owner  => $title,
        group  => $title,
        mode   => '0775',
        before => Service[$title],
    }

    file { "/etc/logrotate.d/${title}":
        content => template('service/logrotate.erb'),
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
    }

    # service init script and activation

    file { "/etc/init/${title}.conf":
        content => template('service/node/upstart.conf.erb'),
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        notify  => Service[$title],
    }

    service { $title:
        ensure     => running,
        hasstatus  => true,
        hasrestart => true,
        provider   => 'upstart',
        require    => [
            Package["${title}/deploy"],
            Package['nodejs-legacy']
        ],
    }

    # Basic firewall
    ferm::service { $title:
        proto => 'tcp',
        port  => $port,
    }

    # Basic monitoring
    monitoring::service { $title:
        description   => $title,
        check_command => "check_http_port_url!${port}!${healthcheck_url}",
    }
}
