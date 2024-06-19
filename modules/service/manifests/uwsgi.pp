# @summary service::uwsgi provides a common wrapper for setting up python services
#   based on uwsgi on. The repository containing the code is assumed to be
#   already deploy by other means.
# @param port Port on which to run the service
# @param config
#   The individual service's config to use. It must be a hash of
#   key => value pairs, or a YAML-formatted string. Note that the complete
#   configuration will be assembled using the bits given here and common
#   service configuration directives.
# @param systemd_user the user to use in the systemd unit
# @param systemd_group the group to use in the systemd unit
# @param no_workers  Number of workers to start.
# @param healthcheck_url
#   The url to monitor the service at. 200 OK is the expected
#   answer. If has_spec it true, this is supposed to be the base url
#   for the spec request
# @param has_spec If the service specifies a swagger spec, use it to thoroughly monitor it
# @param firejail run in firejail
# @param local_logging Whether to store log entries on the target node as well.
# @param icinga_check Whether to include an Icinga check for monitoring the service.
# @param sudo_rules
#   An array of string representing sudo rules in the sudoers format that you
#   want the service to have.
# @param contact_groups  Contact groups for alerting.
# @param add_logging_config
#   Inject logging configuration into the generated uwsgi config file
#   that will route logs to the Logstash ingest host defined in
#   service::configuration::logstash_host and optionally local files if
#   $local_logging is true. Default: true
# @param core_limit
#   This setting adds the LimitCore functionality of the uwsgi's systemd unit.
#   Useful when segfaults are happening regularly and a more detailed report
#   is needed.
#   Values: 'unlimited', 'nG' (n is a number of Gigabytes), or '0' for no core.
# @param nrpe_check_http a list of arguments to pass to check_http
# @example
#    service::uwsgi { 'myservice':
#        port   => 8520,
#        config => {
#           'wsgi-file' => "/path/to/wsgi_file"
#           chdir       => "path_to_dir",
#           venv        => "path_to_virtualenv",
#           param1 => 'val1',
#           param2 => $myvar
#        },
#    }
#
define service::uwsgi(
    Stdlib::Port               $port,
    Hash                       $config                 = {},
    String[1]                  $systemd_user           = 'www-data',
    String[1]                  $systemd_group          = 'www-data',
    Integer                    $no_workers             = $facts['processors']['count'],
    String                     $healthcheck_url        = '/_info',
    Boolean                    $has_spec               = false,
    Boolean                    $firejail               = true,
    Boolean                    $icinga_check           = true,
    Boolean                    $local_logging          = true,
    Array[String]              $sudo_rules             = [],
    Boolean                    $add_logging_config     = true,
    String                     $core_limit             = '0',
    Optional[Nrpe::Check_http] $nrpe_check_http        = undef,
    # lint:ignore:wmf_styleguide
    String        $contact_groups         = lookup('contactgroups', {'default_value' => 'admins'}),
    # lint:endignore
) {
    # Import all common configuration
    include service::configuration

    # we do not allow empty names
    unless $title and size($title) > 0 {
        fail('No name for this resource given!')
    }

    # the local log file name
    $local_logdir = "${service::configuration::log_dir}/${title}"
    $local_logfile = "${local_logdir}/main.log"

    if $add_logging_config {
      if $local_logging {
          ensure_resource('file', '/srv/log', {'ensure' => 'directory' })
          file { $local_logdir:
              ensure => directory,
              owner  => 'www-data',
              group  => 'root',
              mode   => '0755',
              before => Uwsgi::App[$title],
          }
          logrotate::conf { $title:
              ensure  => present,
              content => template('service/logrotate.uwsgi.erb'),
          }
          $log_config_local = {
              log-route => ['local .*', 'logstash .*'],
              logger    => [
                  "local file:${local_logfile}",
                  "logstash socket:${service::configuration::logstash_host}:11514",
              ],
          }
      } else {
          $log_config_local = {
              log-route => ['logstash .*'],
              logger    => [
                  "logstash socket:${service::configuration::logstash_host}:11514",
              ],
          }
      }
      $log_config_shared = {
          log-encoder => [
              # lint:ignore:single_quote_string_with_variables
              # Add a timestamps to local log messages
              'format:local [${strftime:%%Y-%%m-%%dT%%H:%%M:%%S}] ${msgnl}',

              # Encode messages to the logstash logger as json datagrams.
              # msgpack would be nicer
              join([
                  'json:logstash {"@timestamp":"${strftime:%%Y-%%m-%%dT%%H:%%M:%%S}","type":"',
                  $title,
                  '","logger_name":"uwsgi","host":"%h","level":"INFO","message":"${msg}"}'], '')
              #lint:endignore
          ],
      }
      $logging_config = deep_merge($log_config_shared, $log_config_local)
    } else {
      # Use the default log routing of uwsgi which will emit events to
      # stdout/stderr with no special formatting. journald will add
      # timestamps.
      $logging_config = {}
    }

    if !defined(File["/etc/${title}"]) {
        file { "/etc/${title}":
            ensure => directory,
            owner  => 'root',
            group  => 'root',
            mode   => '0755',
        }
    }

    $plugins = debian::codename::ge('bullseye') ? {
        true    => 'python3, logfile, logsocket',
        default => 'python, python3, logfile, logsocket',
    }
    $base_config = {
        plugins     => $plugins,
        master      => true,
        http-socket => "0.0.0.0:${port}",
        processes   => $no_workers,
        die-on-term => true,
    }
    $complete_config = deep_merge($base_config, $logging_config, $config)

    uwsgi::app { $title:
        core_limit    => $core_limit,
        systemd_user  => $systemd_user,
        systemd_group => $systemd_group,
        monitoring    => bool2str($icinga_check, 'present','absent'),
        settings      => {
            uwsgi => $complete_config,
        },
    }

    if $icinga_check {
        if $has_spec {
            # Advanced monitoring
            include service::monitoring

            $fact_ip = $facts['networking']['ip']
            $monitor_url = "http://${fact_ip}:${port}${healthcheck_url}"
            nrpe::monitor_service{ "endpoints_${title}":
                description   => "${title} endpoints health",
                nrpe_command  => "/usr/bin/service-checker-swagger -t 5 ${fact_ip} ${monitor_url}",
                contact_group => $contact_groups,
            }
            # we also support smart-releases
            # TODO: Enable has_autorestart
            service::deployment_script { $name:
                monitor_url     => $monitor_url,
            }
        } elsif $nrpe_check_http {
            nrpe::monitor_service {"uwsgi-nrpe-${title}":
                description   => "uWSGI ${title} (http via nrpe)",
                nrpe_command  => wmflib::argparse($nrpe_check_http, '/usr/lib/nagios/plugins/check_http'),
                contact_group => $contact_groups,
                notes_url     => "https://wikitech.wikimedia.org/wiki/Services/Monitoring/${title}",
            }

        } else {
            # Basic monitoring
            monitoring::service { $title:
                description   => $title,
                check_command => "check_http_port_url!${port}!${healthcheck_url}",
                contact_group => $contact_groups,
                notes_url     => "https://wikitech.wikimedia.org/wiki/Services/Monitoring/${title}",
            }
        }
    }
}
