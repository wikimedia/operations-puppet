# SPDX-License-Identifier: Apache-2.0

class profile::idm(
    Stdlib::Fqdn      $service_name        = lookup('profile::idm::service_fqdn'),
    Optional[Integer] $uwsgi_process_count = lookup('profile::idm::uwsgi_process_count'),
) {
    ferm::service { 'idm_http':
        proto => 'tcp',
        port  => 'http',
    }

    class { 'idm::uwsgi_processes':
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
