# SPDX-License-Identifier: Apache-2.0
class smokeping::web {
    file { '/usr/share/smokeping/www/smokeping.fcgi':
        source => "puppet:///modules/${module_name}/smokeping.fcgi",
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
    }

    acme_chief::cert { 'smokeping':
        puppet_svc => 'apache2',
    }

    $ssl_settings = ssl_ciphersuite('apache', 'strong', true)

    httpd::site { 'smokeping.wikimedia.org':
        content => template('smokeping/apache.conf.erb'),
    }
}
