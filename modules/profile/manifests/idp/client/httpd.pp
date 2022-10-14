# SPDX-License-Identifier: Apache-2.0
# @summary configure mod_auth_cas authentication
# @param cookie_path The location where cas stores information relating to authentication cookies issued
# @param certificate_path the SSL certificate path used for validation
# @param apereo_cas hash holding the login and validation
# @param apache_owner The user apache runs as
# @param apache_group The group apache runs as
# @param sites A hash of sites to be used with profile::httpd::client::idp::site
class profile::idp::client::httpd (
    Apereo_cas::Urls $apereo_cas       = lookup('apereo_cas', Apereo_cas::Urls, 'deep'),
    Stdlib::Unixpath $certificate_path = lookup('profile::idp::client::httpd::certificate_path'),
    Stdlib::Unixpath $cookie_path      = lookup('profile::idp::client::httpd::cookie_path'),
    String[1]        $apache_owner     = lookup('profile::idp::client::httpd::apache_owner'),
    String[1]        $apache_group     = lookup('profile::idp::client::httpd::apache_group'),
    Hash             $sites            = lookup('profile::idp::client::httpd::sites')
) {
    ensure_packages(['libapache2-mod-auth-cas'])

    httpd::mod_conf{'auth_cas':}
    file{$cookie_path:
        ensure => directory,
        owner  => $apache_owner,
        group  => $apache_group,
    }
    $sites.each |Stdlib::Host $vhost, Hash $config| {
        profile::idp::client::httpd::site {$vhost:
            * => $config,
        }
    }
}


