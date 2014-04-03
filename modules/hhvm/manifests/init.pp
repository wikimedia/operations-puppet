# == Class hhvm
#
# Install hhvm and its dependencies.
#
# Can only be applied on Labs.
#
class hhvm {
    if $::realm != 'labs' {
        fail( 'hhvm may only be deployed to Labs.' )
    }

    include hhvm::backports

    package { 'hhvm':
        ensure  => present,
        require => Class['hhvm::backports'],
    }

}
