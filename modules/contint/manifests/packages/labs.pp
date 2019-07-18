# Packages that should only be on labs
#
class contint::packages::labs {
    requires_realm('labs')

    include ::contint::packages::javascript

}
