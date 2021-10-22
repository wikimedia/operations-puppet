# sets up a webserver for wikistats
class profile::wikistats::httpd {

    # TODO: we have this php version logic in  a lot of places we shold have a phpe fact
    $php_module = debian::codename() ? {
        'stretch'  => 'php7.0',
        'buster'   => 'php7.3',
        'bullseye' => 'php7.4',
        default    => fail("unsupported on ${debian::codename()}"),
    }

    class { 'httpd':
        modules => [$php_module, 'rewrite'],
    }
}
