# SPDX-License-Identifier: Apache-2.0
class smokeping::web (
    Wmflib::Ensure $ensure = present,
) {
    file { '/usr/share/smokeping/www/smokeping.fcgi':
        ensure => $ensure,
        source => "puppet:///modules/${module_name}/smokeping.fcgi",
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
    }

    acme_chief::cert { 'smokeping':
        ensure     => $ensure,
        puppet_svc => 'apache2',
    }

    $ssl_settings = ssl_ciphersuite('apache', 'strong', true)

    httpd::site { 'smokeping.wikimedia.org':
        ensure  => $ensure,
        content => template('smokeping/apache.conf.erb'),
    }
}
