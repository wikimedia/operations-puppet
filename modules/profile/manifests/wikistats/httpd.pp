# sets up a webserver for wikistats
class profile::wikistats::httpd {

    # TODO: we have this php version logic in  a lot of places we shold have a phpe fact
    $php_version = debian::codename() ? {
        'buster'   => '7.3',
        'bullseye' => '7.4',
        'bookworm' => '8.2',
        default    => fail("unsupported on ${debian::codename()}"),
    }

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
