# "Compendium" class for nodes supporting various *oid services
# This class is an intermediate step to better design
class role::scb {
    include standard
    include base::firewall
    if $::realm == 'production' {
        include lvs::realserver
    }
}
