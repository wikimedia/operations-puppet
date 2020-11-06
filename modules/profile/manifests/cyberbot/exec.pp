# sets up a an exec node for cyberbot
class profile::cyberbot::exec{

    # TODO: im not sure if this is correct for buster
    # Also wonder if we should create a php_version fact
    $php_version = debian::codename::ge('stretch') ? {
        true    => '7.2',
        default => '5',
    }

    ensure_packages([
        "php${php_version}-mysql", "php${php_version}-mysqlnd", "php${php_version}-cli",
        "php${php_version}-intl", "php${php_version}-json", "php${php_version}-curl"
    ])
}
