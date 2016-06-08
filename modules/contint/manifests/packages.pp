#
# Holds all the packages needed for continuous integration.
#
# FIXME: split this!
#
class contint::packages {

    # Basic utilites needed for all Jenkins slaves
    include ::contint::packages::base

    require_package('openjdk-7-jdk')

    # MediaWiki doc is built directly on contint1001
    package { 'doxygen':
        ensure => present,
    }
    # For Doxygen based documentations
    require_package('graphviz')

    # VisualEditor syncing
    require_package('python-requests')

}
