# == Class contint::packages::postgresql
class contint::packages::postgresql {

    # This is for PHPUNIT tests in ci
    package { [
        'postgresql',
        'postgresql-contrib',
        ]:
        ensure => present,
    }

}
