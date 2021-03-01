# == Class profile::python38
#
# Sharable class that makes python3.8 available.
# Available only for Buster (for the moment).
#
class profile::python38 {

    if debian::codename::eq('buster') {
        if ! defined( Apt::Package_from_component['component-pyall'] ) {
            apt::package_from_component { 'component-pyall':
                component => 'thirdparty/pyall',
                packages  => ['python3.8', 'libpython3.8']
            }
        }
    }
}
