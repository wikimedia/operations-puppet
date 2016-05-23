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
# [*enable*]
#   Whether or not the systemd unit or upstart job for the service
#   should be running. This is passed through to the underlying
#   base::service_unit resource. Default: true.
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
# [*full_config*]
#   Whether the full config has been provided by the caller. If set to true,
#   no config merging will take place and the caller is required to supply the
#   'config' parameter. Default: false
#
# [*no_workers*]
#   Number of workers to start. Default: 'ncpu' (i.e. start as many workers as
#   there are CPUs)
#
# [*heap_limit*]
#   Maximum amount of heap memory each worker is allowed to have in MBs. If
#   surpassed, the worker will be killed and a new one will be spawned. Default:
#   300
#
# [*no_file*]
#   Number of maximum allowed open files for the service, to be set by
#   ulimit. Default: 10000
#
# [*healthcheck_url*]
#   The url to monitor the service at. 200 OK is the expected
#   answer. If has_spec it true, this is supposed to be the base url
#   for the spec request
#
# [*has_spec*]
#   If the service specifies a swagger spec, use it to thoroughly
#   monitor it
#
# [*repo*]
#   The name of the repo to use for deployment. Default: ${title}/deploy
#
# [*starter_module*]
#   The service's starter module loaded by service-runner on start-up. Default:
#   ./src/app.js
#
# [*starter_script*]
#   The script used for starting the service. Default: src/server.js
#
# [*local_logging*]
#   Whether to store log entries on the target node as well. Default: true
#
# [*auto_refresh*]
#   Whether the service should be automatically restarted after config changes.
#   Default: true
#
# [*init_restart*]
#  Whether the service should be respawned by the init system in case of
#  crashes. Default: true
#
# [*deployment*]
#   If this value is set to 'scap3' then deploy via scap3, otherwise, use trebuchet
#   Default: undef
#
# [*deployment_user*]
#   The user that will own the service code. Only applicable when
#   $deployment ='scap3'. Default: $title
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
define service::node(
    $port,
    $enable          = true,
    $config          = undef,
    $full_config     = false,
    $no_workers      = 'ncpu',
    $heap_limit      = 300,
    $no_file         = 10000,
    $healthcheck_url = '/_info',
    $has_spec        = false,
    $repo            = "${title}/deploy",
    $starter_module  = './src/app.js',
    $starter_script  = 'src/server.js',
    $local_logging   = true,
    $auto_refresh    = true,
    $init_restart    = true,
    $deployment      = undef,
    $deployment_user = 'deploy-service',
) {
    case $deployment {
        'scap3': {
            if ! defined(Service::Deploy::Trebuchet[$repo]) {
                service::deploy::scap{ $repo:
                    service_name => $title,
                    user         => $deployment_user,
                    before       => Base::Service_unit[$title],
                    manage_user  => true,
                }
            }
        }
        default: {
            if ! defined(Service::Deploy::Trebuchet[$repo]) {
                service::deploy::trebuchet{ $repo:
                    before => Base::Service_unit[$title]
                }
            }
        }
    }

    # Import all common configuration
    include service::configuration

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

    # configuration management
    if $full_config {
        unless $config and size($config) > 0 {
            fail('A config needs to be specified when full_config == true!')
        }
        $complete_config = $config
    } else {
        # load configuration; if none is provided, assume it's
        # in a standard location
        $local_config = $config ? {
            undef   => template("service/node/${title}_config.yaml.erb"),
            default => $config,
        }
        $complete_config = merge_config(
            template('service/node/config.yaml.erb'),
            $local_config
        )
    }

    # Software and the deployed code, firejail for containment
    require_package('nodejs', 'nodejs-legacy', 'firejail')

    # User/group
    group { $title:
        ensure => present,
        name   => $title,
        system => true,
        before => Service[$title],
    }

    user { $title:
        gid    => $title,
        home   => '/nonexistent',
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
        content => $complete_config,
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        tag     => "${title}::config",
    }

    if $auto_refresh {
        # if the service should be restarted after a
        # config change, specify the notify/before requirement
        File["/etc/${title}/config.yaml"] ~> Service[$title]
    } else {
        # no restart should happen, just ensure the file is
        # created before the service
        File["/etc/${title}/config.yaml"] -> Service[$title]
    }

    if $local_logging {
        file { $local_logdir:
            ensure => directory,
            owner  => $title,
            group  => 'root',
            mode   => '0755',
            before => Service[$title],
        }
        file { "/etc/logrotate.d/${title}":
            content => template('service/logrotate.erb'),
            owner   => 'root',
            group   => 'root',
            mode    => '0444',
        }
        # convenience script to pretty-print logs
        file { "/usr/local/bin/tail-${title}":
            content => template('service/node/tail-log.erb'),
            owner   => 'root',
            group   => 'root',
            mode    => '0755'
        }
        # we first placed tail-${title} in /usr/bin, so make sure
        # it's not there any more
        file { "/usr/bin/tail-${title}":
            ensure => absent,
        }
    }

    # service init script and activation
    base::service_unit { $title:
        ensure         => present,
        systemd        => true,
        upstart        => true,
        template_name  => 'node',
        refresh        => $auto_refresh,
        service_params => {
            enable     => $enable,
            ensure     => ensure_service($enable),
            hasstatus  => true,
            hasrestart => true,
        },
    }

    # Basic firewall
    ferm::service { $title:
        proto => 'tcp',
        port  => $port,
    }

    # Monitoring
    $ensure_monitoring = $enable ? {
        true  => 'present',
        false => 'absent',
    }

    if $has_spec {
        # Advanced monitoring
        include service::monitoring

        $monitor_url = "http://${::ipaddress}:${port}${healthcheck_url}"
        $check_command = "/usr/local/lib/nagios/plugins/service_checker -t 5 ${::ipaddress} ${monitor_url}"
        file { "/usr/local/bin/check-${title}":
            content => inline_template(
                '<%= ["#!/bin/sh", @check_command].join("\n") %>'
            ),
            owner   => 'root',
            group   => 'root',
            mode    => '0755',
        }
        nrpe::monitor_service{ "endpoints_${title}":
            ensure       => $ensure_monitoring,
            description  => "${title} endpoints health",
            nrpe_command => "/usr/local/bin/check-${title}",
            subscribe    => File["/usr/local/bin/check-${title}"],
        }
        # we also support smart-releases
        service::deployment_script { $name:
            monitor_url     => $monitor_url,
            has_autorestart => $auto_refresh,
        }
    } else {
        # Basic monitoring
        monitoring::service { $title:
            ensure        => $ensure_monitoring,
            description   => $title,
            check_command => "check_http_port_url!${port}!${healthcheck_url}",
        }
    }

}
