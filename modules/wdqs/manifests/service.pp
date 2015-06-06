# == Class: wdqs::service
#
# Provisions WDQS service package
#
class wdqs::service {
    
    if $::realm == 'labs' {
        ## don't do anything
    } else {
        package { 'wdqs':
            ensure   => present,
            provider => 'trebuchet',
        }
    }

}
