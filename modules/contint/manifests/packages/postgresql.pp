# == Class contint::packages::postgresql
# for PHP Unit tests (T39602, T22342)
class contint::packages::postgresql {

    package { [
        'postgresql',
        'postgresql-contrib',
        ]:
        ensure => present,
    }

}
