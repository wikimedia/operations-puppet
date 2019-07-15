# Packages that should only be on labs
#
class contint::packages::labs {
    requires_realm('labs')

    include ::contint::packages::javascript
    include ::contint::packages::ruby

    # Database related
    package { [
        'sqlite3',
        ]:
        ensure => present,
    }

}
