# the apache setup for the wikistats site
class wikistats::web (
    $wikistats_host,
    ) {

    if os_version('debian >= stretch') {
        $php_version = '7.0'
    } else {
        $php_version = '5'
    }

    $apache_php_package = "libapache2-mod-php${php_version}"

    require_package($apache_php_package')

    include ::apache::mod::rewrite

    apache::site { $wikistats_host:
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
