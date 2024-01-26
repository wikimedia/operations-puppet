# SPDX-License-Identifier: Apache-2.0
# Class: profile::hadoop::httpd
#
# Sets up a webserver for Hadoop UIs
class profile::hadoop::httpd(
    Optional[Array[String[1]]] $extra_modules = lookup('profile::hadoop::httpd::extra_modules', { default_value => [] }),
    Boolean                    $http_only     = lookup('profile::hadoop::httpd::http_only', { default_value => false }),
) {
    $modules = ['proxy_http', 'proxy', 'proxy_html', 'headers', 'xml2enc', 'auth_basic', 'authnz_ldap'] + $extra_modules;
    class { '::httpd':
        modules   => $modules,
        http_only => $http_only,
    }

    firewall::service { 'hadoop-ui-http':
        proto    => 'tcp',
        port     => 80,
        src_sets => ['CACHES'],
    }
}
