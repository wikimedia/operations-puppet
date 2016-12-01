# == Class: wdqs::packages
#
# Provisions WDQS package and dependencies.
#
class wdqs::packages {
    include ::java::tools

    require_package('openjdk-8-jdk')
    require_package('curl')
}
