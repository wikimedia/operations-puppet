# == Class contint::packages::doxygen
#
# Dependencies to run Doxygen. Used by MediaWiki, some extensions and random
# other projects.
#
# Graphviz is used to generate call graphs.
class contint::packages::doxygen {

    require_package('doxygen')
    require_package('graphviz')

}
