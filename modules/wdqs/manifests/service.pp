# == Class: wdqs::service
#
# Provisions WDQS service package
#
class wdqs::service {
    
    package { 'wdqs':
            ensure   => present,
            provider => 'trebuchet',
    }

}
