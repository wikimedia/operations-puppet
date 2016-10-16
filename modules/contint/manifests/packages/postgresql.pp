# == Class contint::packages::postgresql
class contint::packages::postgresql {

    # This is for PHPUNIT tests in ci
    # Tasks T39602 and T22343
    package { [
        'postgresql',
        'postgresql-contrib',
        ]:
        ensure => present,
    }

}
