# SPDX-License-Identifier: Apache-2.0
# @summary profile to configure librenms website
class profile::librenms::web {

    require profile::librenms

    $sitename       = $profile::librenms::sitename
    $install_dir    = $profile::librenms::install_dir
    $active_server  = $profile::librenms::active_server
    $auth_mechanism = $profile::librenms::auth_mechanism
    $ssl_settings   = ssl_ciphersuite('apache', 'strong', true)

    acme_chief::cert { 'librenms':
        puppet_svc => 'apache2',
    }

    if $auth_mechanism == 'sso' {
        include profile::idp::client::httpd
    } else {
        httpd::site { $sitename:
            content => template('profile/librenms/apache.conf.erb'),
        }
    }
}
