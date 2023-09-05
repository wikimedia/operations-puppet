# sets up a an exec node for cyberbot
class profile::cyberbot::exec{

    # switch to a fact once T271196 is resolved
    $php_version = debian::codename() ? {
        'bookworm' => '8.2',
        'bullseye' => '7.4',
        'buster'   => '7.3',
        default    => fail("profile::cyberbot::exec currently unsupported on debian ${debian::codename()}"),
    }

    ensure_packages([
        "php${php_version}-mysql", "php${php_version}-mysqlnd", "php${php_version}-cli",
        "php${php_version}-intl", "php${php_version}-json", "php${php_version}-curl"
    ])
}
