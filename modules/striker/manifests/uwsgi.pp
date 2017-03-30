# = Class: striker::uwsgi
#
# Striker is a Django application for managing data related to Tool Labs
# tools.
#
# == Parameters:
# [*port*]
#   Port that uWSGI demon should listen on
# [*config*]
#   Configuration for the deployed Django application. Value should be
#   a multi-dimentional hash of values.
# [*deploy_dir*]
#   Directory that Striker will be deployed to via scap3.
#   Default /srv/deployment/striker/deploy.
# [*venv_dir*]
#   Directory to create/manage Python virtualenv in.
#   Default /srv/deployment/striker/venv.
# [*secret_config*]
#   Additional configuration for the deployed Django application. Value should
#   be a multi-dimentional hash of values. Useful for setting configuration
#   values that for one reason or another cannot be provided via `config`
#   (probably because the values need to be kept out of public hiera files).
#   Default {}.
#
class striker::uwsgi(
    $port,
    $config,
    $deploy_dir    = '/srv/deployment/striker/deploy',
    $venv_dir      = '/srv/deployment/striker/venv',
    $secret_config = {},
){
    requires_os('ubuntu trusty')
    include service::configuration

    # Packages needed by python wheels
    require_package(
        'libffi6',
        'libldap-2.4-2',
        'libmysqlclient18',
        'libsasl2-2',
        'libssl1.0.0',
        'python3',
        'python3-wheel',
        'python-virtualenv',
    )

    $log_dir = "${service::configuration::log_dir}/striker"
    $logstash_host = $config['logging']['LOGSTASH_HOST']
    $logstash_port = $config['logging']['LOGSTASH_PORT']
    service::uwsgi { 'striker':
        port            => $port,
        config          => {
            need-plugins => 'python3, logfile, logsocket',
            chdir        => "${deploy_dir}/striker",
            venv         => $venv_dir,
            wsgi         => 'striker.wsgi',
            vacuum       => true,

            logger       => [
                "local file:${log_dir}/main.log",
                "logstash socket:${logstash_host}:${logstash_port}",
            ],
            log-route    => ['local .*', 'logstash .*'],
            log-encoder  => [
                # lint:ignore:single_quote_string_with_variables
                # Add a timestamps to local log messages
                'format:local [${strftime:%%Y-%%m-%%dT%%H:%%M:%%S}] ${msgnl}',

                # Encode messages to the logstash logger as json datagrams.
                # msgpack would be nicer, but the jessie uwsgi package doesn't
                # include the msgpack formatter.
                'json:logstash {"@timestamp":"${strftime:%%Y-%%m-%%dT%%H:%%M:%%S}","type":"striker","logger_name":"uwsgi","host":"%h","level":"INFO","message":"${msg}"}',
                #lint:endignore
            ],

            # Access log apache combined log format + time to generate response
            # Mimics the WMF Apache logging standard
            req-logger   => "file:${log_dir}/access.log",
            log-format   => '%(addr) - %(user) [%(ltime)] "%(method) %(uri) (proto)" %(status) %(size) "%(referer)" "%(uagent)" %(micros)',
        },
        healthcheck_url => '/',
        repo            => 'striker/deploy',
        sudo_rules      => [
            'ALL=(root) NOPASSWD: /usr/sbin/service uwsgi-striker restart',
            'ALL=(root) NOPASSWD: /usr/sbin/service uwsgi-striker start',
            'ALL=(root) NOPASSWD: /usr/sbin/service uwsgi-striker status',
            'ALL=(root) NOPASSWD: /usr/sbin/service uwsgi-striker stop',
        ],
    }

    # Our ini() function does a shallow merge rather than a deep merge, so
    # merge the config sections before passing to ini() below.
    $complete_config = deep_merge($config, $secret_config)

    file { '/etc/striker/striker.ini':
        ensure  => 'present',
        owner   => 'root',
        group   => 'www-data',
        mode    => '0440',
        content => ini($complete_config),
        notify  => Uwsgi::App['striker'],
    }
}
# vim:sw=4:ts=4:sts=4:ft=puppet:
