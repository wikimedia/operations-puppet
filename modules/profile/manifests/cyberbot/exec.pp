# sets up a an exec node for cyberbot
class profile::cyberbot::exec{

    if os_version('debian >= stretch') {
        $php_version = '7.2'
    } else {
        $php_version = '5'
    }

    require_package("php${php_version}-mysql")
    require_package("php${php_version}-mysqlnd")
    require_package("php${php_version}-cli")
    require_package("php${php_version}-intl")
    require_package("php${php_version}-json")
    require_package("php${php_version}-curl")
}
