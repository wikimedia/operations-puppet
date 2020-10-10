# webserver setup for a wikistats site
class wikistats::web (
    Stdlib::Fqdn $wikistats_host,
    String $php_version = '7.3',
){
    $php_xml_pkg = "php${php_version}-xml"
    $php_http_module_pkg = "libapache2-mod-php${php_version}"

    require_package($php_xml_pkg, $php_http_module_pkg)

    httpd::site { $wikistats_host:
        content => template('wikistats/apache/wikistats.erb'),
        require => Package[$php_http_module_pkg],
    }

    file { '/var/www/wikistats':
        ensure => directory,
        mode   => '0755',
        owner  => 'wikistatsuser',
        group  => 'www-data',
    }
}
