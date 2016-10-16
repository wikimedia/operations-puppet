# == Class contint::packages::postgresql
class contint::packages::postgresql {

    package { [
        'postgresql',
        'postgresql-contrib',
        ]:
        ensure => present,
    }

}
