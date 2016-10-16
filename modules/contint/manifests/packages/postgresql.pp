# == Class contint::packages::postgresql
class contint::packages::postgresql {

    # This is for PHPUNIT tests in ci
    # Task T39602
    # Task T22343
    package { [
        'postgresql',
        'postgresql-contrib',
        ]:
        ensure => present,
    }

}
