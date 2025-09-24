# sets up a webserver for wikistats
class profile::wikistats::httpd {

    $php_version = wmflib::debian_php_version()

    class { 'httpd':
        modules => ["php${php_version}", 'rewrite'],
    }

    ensure_packages([
        "php${php_version}-xml",
        "libapache2-mod-php${php_version}",
    ])

    file { '/var/www/wikistats':
        ensure => directory,
        mode   => '0755',
        owner  => 'wikistatsuser',
        group  => 'www-data',
    }

    httpd::site { 'wikistats-cloud-vps':
        content => template('wikistats/apache/wikistats.erb'),
        require => Package["libapache2-mod-php${php_version}"],
    }
}
