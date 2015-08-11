# "Compendium" class for nodes supporting various *oid services
# This class is an intermediate step to better design
@monitoring::group { 'scb_eqiad': description => 'Service Cluster B servers' }
class role::scb {
    include standard
    include base::firewall
    if $::realm == 'production' {
        include lvs::realserver
    }
}
