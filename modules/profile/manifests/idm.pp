# SPDX-License-Identifier: Apache-2.0

class profile::idm(
    Stdlib::Fqdn     $service_fqdn              = lookup('profile::idm::service_fqdn'),
    String           $django_secret_key         = lookup('profile::idm::server::django_secret_key'),
    String           $django_mysql_db_host      = lookup('profile::idm::server::django_mysql_db_host'),
    String           $django_mysql_db_password  = lookup('profile::idm::server::django_mysql_db_password'),
    String           $django_mysql_db_user      = lookup('profile::idm::server::django_mysql_db_user', {'default_value' => 'idm'}),
    String           $django_mysql_db_name      = lookup('profile::idm::server::django_mysql_db_name', {'default_value' => 'idm'}),
    String           $deploy_user               = lookup('profile::idm::deploy_user', {'default_value'                  => 'www-data'}),
    Integer          $uwsgi_process_count       = lookup('profile::idm::uwsgi_process_count', {'default_value'          => 4}),
    Boolean          $development               = lookup('profile::idm::development', {'default_value'                  => false}),
    Boolean          $production                = lookup('profile::idm::production', {'default_value'                   => false}),
    Boolean          $envoy_termination         = lookup('profile::idm::envoy_termination', {'default_value'            => false}),
    Apereo_cas::Urls $apereo_cas                = lookup('apereo_cas'),
    Hash             $ldap_config               = lookup('ldap'),
    String           $oidc_key                  = lookup('profile::idm::oidc_key'),
    String           $oidc_secret               = lookup('profile::idm::oidc_secret', {'default_value' => 'secret'}),
) {

    ensure_packages(['python3-django-uwsgi'])

    $etc_dir = '/etc/bitu'
    $base_dir = '/srv/idm'
    $log_dir = '/var/log/idm'
    $media_dir = "${base_dir}/media"
    $static_dir = "${base_dir}/static"
    $project = 'bitu'
    $uwsgi_socket = "/run/uwsgi/${project}.sock"


    $production_str = $production.bool2str('production', 'staging')
    $oidc_endpoint = $apereo_cas[$production_str]['oidc_endpoint']

    include passwords::ldap::production
    class{ 'sslcert::dhparam': }

    if $envoy_termination {
      include profile::tlsproxy::envoy
      $ferm_port = 443
      profile::auto_restarts::service { 'envoyproxy': }
    } else {
      # In cloud we use the shared wmfcloud proxy for tls termination
      $ferm_port = 80
    }

    ferm::service { 'idm_http':
        proto => 'tcp',
        port  => $ferm_port,
    }


    file { [$static_dir, $media_dir, $etc_dir, $log_dir] :
        ensure => directory,
        owner  => $deploy_user,
        group  => $deploy_user,
    }

    class { 'idm::deployment':
        project                  => $project,
        service_fqdn             => $service_fqdn,
        django_secret_key        => $django_secret_key,
        django_mysql_db_name     => $django_mysql_db_name,
        django_mysql_db_host     => $django_mysql_db_host,
        django_mysql_db_user     => $django_mysql_db_user,
        django_mysql_db_password => $django_mysql_db_password,
        base_dir                 => $base_dir,
        deploy_user              => $deploy_user,
        etc_dir                  => $etc_dir,
        log_dir                  => $log_dir,
        static_dir               => $static_dir,
        production               => $production,
        oidc                     => {
            key      => $oidc_key,
            secret   => $oidc_secret,
            endpoint => $oidc_endpoint
        },
        ldap_config              => $ldap_config + {
            proxypass   => $passwords::ldap::production::proxypass,
        },
    }

    uwsgi::app{ $project:
        settings => {
            uwsgi => {
                'plugins'      => 'python3',
                'project'      => $project,
                'uid'          => $deploy_user,
                'base'         => "${base_dir}/${project}",
                'env'          => [
                    "PYTHONPATH=/etc/${project}:\$PYTHONPATH",
                    'DJANGO_SETTINGS_MODULE=settings'
                ],
                'chdir'        => '%(base)/',
                'module'       => '%(project).wsgi:application',
                'master'       => true,
                'processes'    => $uwsgi_process_count,
                'socket'       => $uwsgi_socket,
                'chown-socket' => $deploy_user,
                'chmod-socket' => 660,
                'vacuum'       => true,
                'virtualenv'   => $idm::deployment::venv,
            }
        }
    }

    class {'httpd':
        modules => ['proxy_http', 'proxy', 'proxy_uwsgi']
    }

    httpd::site { 'idm':
        ensure  => present,
        content => template('idm/idm-apache-config.erb'),
    }
}
