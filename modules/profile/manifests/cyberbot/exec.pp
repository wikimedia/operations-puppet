# sets up a an exec node for cyberbot
class profile::cyberbot::exec{

    $php_version = wmflib::debian_php_version()

    ensure_packages([
        "php${php_version}-mysql", "php${php_version}-mysqlnd", "php${php_version}-cli",
        "php${php_version}-intl", "php${php_version}-json", "php${php_version}-curl"
    ])
}
