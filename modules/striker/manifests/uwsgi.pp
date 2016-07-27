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
    requires_os('Debian >= jessie')
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
        'virtualenv',
    )

    $log_dir = "${service::configuration::log_dir}/striker"
    $logstash = $config['logging']['LOGSTASH_HOST']
    service::uwsgi { 'striker':
        port            => $port,
        config          => {
            need-plugins    => 'python3',
            chdir           => "${deploy_dir}/striker",
            venv            => $venv_dir,
            wsgi            => 'striker.wsgi',
            vacuum          => true,
            threaded-logger => true,
            logger          => [
                "file:${log_dir}/main.log",
                "logstash socket:${logstash}:1717",
            ],
            # Encode messages to the logstash logger as msgpack datagrams
            log-encoder     => 'msgpack:logstash map:5|str:@timestamp|strftime:%%Y-%%m-%%dT%%H:%%M:%%S|str:type|str:striker|str:logger_name|str:uwsgi|str:host|str:%h|str:message|msg',
            # Access logs are only kept locally
            req-logger      => "file:${log_dir}/access.log",
            # Apache combined log format + time to generate response
            # Mimics the WMF Apache logging standard
            log-req-encoder => '%(addr) - %(user) [%(ltime)] "%(method) %(uri) (proto)" %(status) %(size) "%(referer)" "%(uagent)" %(micros)',
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

    # OUr ini() function does a shallow merge rather than a deep merge, so
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
