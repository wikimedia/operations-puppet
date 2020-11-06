# sets up a webserver for wikistats
class profile::wikistats::httpd {

    # TODO: we have this php version logic in  a lot of places we shold have a phpe fact
    $php_module = debian::codename::eq('buster') ? {
        true    => 'php7.3',
        default => 'php7.0',
    }

    class { 'httpd':
        modules => [$php_module, 'rewrite'],
    }
}
