# SPDX-License-Identifier: Apache-2.0
class profile::pontoon::frontend (
  $public_domain = lookup('public_domain'),
) {
    $public_services = wmflib::service::fetch().filter |$name, $config| {
        ('public_endpoint' in $config and 'role' in $config)
    }

    class { 'pontoon::public_lb':
        services_config => $public_services,
        public_domain   => $public_domain,
    }

    class { '::httpd':
        modules => ['rewrite'],
    }

    class { 'pontoon::public_certs':
        services_config => $public_services,
        public_domain   => $public_domain,
    }

    ferm::service { 'pontoon-frontend':
        proto => 'tcp',
        port  => '(80 443)',
    }
}
