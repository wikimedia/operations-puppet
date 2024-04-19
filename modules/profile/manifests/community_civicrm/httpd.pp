# SPDX-License-Identifier: Apache-2.0
# sets up a webserver for community crm
#
# @param site_name endpoint dns name for civicrm web interface
# @param web_root path that holds web files for reference by the webserver

class profile::community_civicrm::httpd (
    Stdlib::Fqdn $site_name = lookup('profile::community_civicrm::httpd::site_name', {'default_value' => 'community-crm.wikimedia.org'}),
    Stdlib::Unixpath $web_root = lookup('profile::community_civicrm::httpd::web_root', {'default_value' => '/var/www/community_civicrm/web'}),
) {

    $php_version = wmflib::debian_php_version()

    class { 'httpd':
        modules => ["php${php_version}", 'rewrite'],
    }

    ensure_packages([
        "php${php_version}-xml",
        "libapache2-mod-php${php_version}",
    ])

    file { '/var/www':
        ensure => directory,
        owner  => 'www-data',
        group  => 'www-data',
    }

    file { '/var/www/community_civicrm':
        ensure => directory,
        mode   => '0755',
        owner  => 'www-data',
        group  => 'www-data',
    }

    httpd::site { 'community-crm':
        content => template('profile/community_civicrm/community-civi.apache.erb'),
        require => Package["libapache2-mod-php${php_version}"],
    }

    firewall::service { 'civicrm_http':
        proto => 'tcp',
        port  => [80],
    }

}
