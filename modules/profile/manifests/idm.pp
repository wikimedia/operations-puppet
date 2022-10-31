# SPDX-License-Identifier: Apache-2.0

class profile::idm(
    Stdlib::Fqdn $service_name        = lookup('profile::idm::service_fqdn'),
    String       $deploy_user         = lookup('profile::idm::deploy_user', {'default_value' => 'www-data'}),
    Integer      $uwsgi_process_count = lookup('profile::idm::uwsgi_process_count', {'default_value' => 4}),
    Boolean      $development         = lookup('profile::idm::development',  {'default_value' => False}),
) {

    $base_dir = '/srv/idm'

    ferm::service { 'idm_http':
        proto => 'tcp',
        port  => 'http',
    }

    class { 'idm::deployment':
        base_dir    => $base_dir,
        deploy_user => $deploy_user,
        development => $development,
    }

    class { 'idm::uwsgi_processes':
        base_dir            => $base_dir,
        uwsgi_process_count => $uwsgi_process_count,
    }

    class {'httpd':
        modules => ['proxy_http', 'proxy', 'uwsgi']
    }

    httpd::site { 'idm':
        ensure  => present,
        content => template('idm/idm-apache-config.erb'),
    }
}
