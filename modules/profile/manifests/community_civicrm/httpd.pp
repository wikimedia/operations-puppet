# SPDX-License-Identifier: Apache-2.0
# sets up a webserver for community crm
class profile::community_civicrm::httpd {

    $web_root = '/var/www/community_civicrm/web'
    $site_name = 'community-crm.wmcloud.org'

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
