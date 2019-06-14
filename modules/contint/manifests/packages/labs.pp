# Packages that should only be on labs
#
class contint::packages::labs {
    requires_realm('labs')

    require ::contint::packages::apt

    # We're no longer installing PHP on app servers starting with
    # jessie, but we still need it for CI
    if os_version('debian == jessie') {
        include ::contint::packages::php5
    }

    include ::contint::packages::javascript
    include ::contint::packages::php
    include ::contint::packages::ruby

    # Database related
    package { [
        'sqlite3',
        ]:
        ensure => present,
    }

}
