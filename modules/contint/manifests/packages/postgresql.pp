# == Class contint::packages::postgresql
class contint::packages::postgresql {

    # This is for PHPUNIT tests in ci (T39602), (T22343)
    package { [
        'postgresql',
        'postgresql-contrib',
        ]:
        ensure => present,
    }

}
