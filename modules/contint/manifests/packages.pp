#
# Holds all the packages needed for continuous integration.
#
# FIXME: split this!
#
class contint::packages {

    # Basic utilites needed for all Jenkins slaves
    include ::contint::packages::base

}
