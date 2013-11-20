# Packages that should only be on labs
#
class contint::packages::labs {

    if $::realm == 'production' {
        fail( 'contint::packages::labs must not be used in production' )
    }

    include contint::packages

    package { [
        'npm',
        'python-pip',
        ]: ensure => present,
    }

}
