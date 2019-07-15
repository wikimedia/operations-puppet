# == Class: striker::uwsgi
#
# Striker is a Django application for managing data related to Toolforge
# tools.
#
# === Parameters:
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
# === Examples
#
#  class {'striker::uwsgi':
#    port                     => 8080,
#    config         => {
#      'debug'                => { 'DEBUG' => false },
#      'ldap'           => {
#        'SERVER_URI'         => 'ldap://example.net:389',
#        'BIND_USER'          => 'example_user',
#        'TLS'                => true,
#      },
#      'oauth'                => { 'CONSUMER_KEY' => 'BEEF' },
#      'phabricator'          => { 'USER' => 'example_phab_user' },
#      'db'             => {
#        'ENGINE'             => 'django.db.backends.mysql',
#        'NAME'               => 'db_name',
#        'USER'               => 'db_user',
#        'HOST'               => 'db.example.net',
#        'PORT'               => 3306,
#      },
#      'cache'                => { 'LOCATION' => '127.0.0.1:11212' },
#      'xff'            => {
#        'USE_XFF_HEADER'     => true,
#        'TRUSTED_PROXY_LIST' => '127.0.0.1',
#      },
#      'https'                => { 'REQUIRE_HTTPS' => true },
#      'logging'        => {
#        'HANDLERS'           => 'file logstash',
#        'FILE_FILENAME'      => '/srv/log/striker/striker.log',
#        'LOGSTASH_HOST'      => 'logstash.example.net',
#        'LOGSTASH_PORT'      => 11514,
#      }
#      'static'               => { 'STATIC_ROOT' => '/srv/www' },
#      'openstack'            => { 'URL' => 'http://openstack.example.net/v3' },
#     }
#     secret_config => {
#       'secrets'       => {
#         'SECRET_KEY'        => '50 char random string used by Django to salt things',
#       },
#      'ldap'            => {
#         'BIND_PASSWORD'     => 'password for striker::uwsgi::config::ldap::BIND_USER',
#       },
#      'oauth'           => {
#         'CONSUMER_SECRET'   => 'secret for striker::uwsgi::config::oauth::CONSUMER_KEY',
#       },
#      'phabricator'     => {
#         'TOKEN              => 'API token for striker::uwsgi::config::phabricator::USER',
#       },
#      'db'              => {
#         'password'          => 'password for striker::uwsgi::config::db::USER'
#      }
#    }
#  }
#
class striker::uwsgi(
    $port,
    $config,
    $deploy_dir    = '/srv/deployment/striker/deploy',
    $venv_dir      = '/srv/deployment/striker/venv',
    $secret_config = {},
){
    include service::configuration

    # Packages needed by python wheels
    require_package(
        'libffi6',
        'libldap-2.4-2',
        'libmariadbclient18',
        'libsasl2-2',
        'python3-venv',
        'python3-virtualenv',
        'python3-wheel',
    )

    # Striker is controlled via a custom systemd unit (uwsgi-striker),
    #  so avoid the generic uwsgi sysvinit script
    exec { 'mask_default_uwsgi':
        command => '/bin/systemctl mask uwsgi.service',
        creates => '/etc/systemd/system/uwsgi.service',
    }

    $log_dir = "${service::configuration::log_dir}/striker"
    $logstash_host = $config['logging']['LOGSTASH_HOST']
    $logstash_port = $config['logging']['LOGSTASH_PORT']
    service::uwsgi { 'striker':
        port               => $port,
        config             => {
            need-plugins => 'python3, logfile',
            chdir        => "${deploy_dir}/striker",
            venv         => $venv_dir,
            wsgi         => 'striker.wsgi',
            vacuum       => true,
            http-socket  => "127.0.0.1:${port}",
            # T170189: make sure Python has a sane default encoding
            env          => [
                'LANG=C.UTF-8',
                'PYTHONENCODING=utf-8',
            ],

            # Access log apache combined log format + time to generate response
            # Mimics the WMF Apache logging standard
            req-logger   => "file:${log_dir}/access.log",
            log-format   => '%(addr) - %(user) [%(ltime)] "%(method) %(uri) (proto)" %(status) %(size) "%(referer)" "%(uagent)" %(micros)',
        },
        healthcheck_url    => '/',
        icinga_check       => false,
        repo               => 'striker/deploy',
        sudo_rules         => [
            'ALL=(root) NOPASSWD: /usr/sbin/service uwsgi-striker restart',
            'ALL=(root) NOPASSWD: /usr/sbin/service uwsgi-striker start',
            'ALL=(root) NOPASSWD: /usr/sbin/service uwsgi-striker status',
            'ALL=(root) NOPASSWD: /usr/sbin/service uwsgi-striker stop',
        ],
        # T217932: Use default logging to stderr which will be picked up by
        # journald and can be routed to rsyslog from there.
        add_logging_config => false,
    }

    base::service_auto_restart { 'uwsgi-striker': }

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
