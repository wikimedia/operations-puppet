#
# Holds all the packages needed for continuous integration.
#
# FIXME: split this!
#
class contint::packages {

    # Basic utilites needed for all Jenkins slaves
    include ::contint::packages::base

    # We're no longer installing PHP on app servers starting with
    # jessie, but we still need it for CI
    if os_version('debian == jessie') {
        include ::mediawiki::packages::php5
    }

    require_package('openjdk-7-jdk')

    # MediaWiki doc is built directly on contint1001
    require_package('doxygen')

    # For Doxygen based documentations
    require_package('graphviz')

    # VisualEditor syncing
    require_package('python-requests')

}
