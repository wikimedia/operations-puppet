# the apache setup for the wikistats site
class wikistats::web (
    Stdlib::Fqdn $wikistats_host,
) {

    if os_version('debian == buster') {
        require_package('php7.3-xml')
        $apache_php_package = 'libapache2-mod-php7.3'
    } else {
        require_package('php7.0-xml')
        $apache_php_package = 'libapache2-mod-php7.0'
    }

    require_package($apache_php_package)

    httpd::site { $wikistats_host:
        content => template('wikistats/apache/wikistats.erb'),
        require => Package[$apache_php_package],
    }

    file { '/var/www/wikistats':
        ensure => directory,
        mode   => '0755',
        owner  => 'wikistatsuser',
        group  => 'www-data',
    }
}
