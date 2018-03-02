# == Class: wdqs::monitor::blazegraph
#
# Create diamond monitoring for Blazegraph
#
class wdqs::monitor::blazegraph {
    require ::wdqs::service

    diamond::collector { 'Blazegraph':
        ensure => absent,
    }

}
