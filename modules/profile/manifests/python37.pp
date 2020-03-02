# == Class profile::python37
#
# Sharable class that makes python3.7 available.
#
class profile::python37 {

    if os_version('debian <= stretch') {
        if ! defined( Apt::Package_from_component['component-pyall'] ) {
            apt::package_from_component { 'component-pyall':
                component => 'component/pyall',
                packages  => ['python3.7', 'libpython3.7']
            }
        }
    } else {
        require_package('python3.7', 'libpython3.7')
    }

}
