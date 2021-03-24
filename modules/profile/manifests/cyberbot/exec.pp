# sets up a an exec node for cyberbot
class profile::cyberbot::exec{

    # switch to a fact once T271196 is resolved
    $php_version = '7.2'

    ensure_packages([
        "php${php_version}-mysql", "php${php_version}-mysqlnd", "php${php_version}-cli",
        "php${php_version}-intl", "php${php_version}-json", "php${php_version}-curl"
    ])
}
