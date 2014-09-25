# = Class: icinga::packages
#
# Setup packages required to run icinga. 
class icinga::packages {

    package { [
        'icinga', 
        'icinga-doc',
    ] :
        ensure => latest,
    }
}
