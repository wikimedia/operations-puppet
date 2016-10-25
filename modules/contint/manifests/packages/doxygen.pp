# == Class contint::packages::doxygen
#
# Dependencies to run Doxygen. Used by MediaWiki, some extensions and random
# other projects.
#
# Graphviz is used to generate call graphs.
class contint::packages::doxygen {

    package { 'doxygen':
        ensure => present,
    }
    package { 'graphviz':
        ensure => present,
    }

}
