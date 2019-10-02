# sets up a webserver for wikistats
class profile::wikistats::httpd {

    if os_version('debian == buster') {
        $php_module = 'php7.3'
    } else {
        $php_module = 'php7.0'
    }

    class { '::httpd':
        modules => [$php_module, 'rewrite'],
    }
}
