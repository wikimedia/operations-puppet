# == Class: wdqs::packages
#
# Provisions WDQS package and dependencies.
#
class wdqs::packages {
    include ::java::tools

    require_package('openjdk-7-jdk')
    require_package('curl')
    require_package('maven')
}
