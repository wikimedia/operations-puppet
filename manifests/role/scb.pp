# "Compendium" class for nodes supporting various *oid services
# This class is an intermediate step to better design
class role::scb {
    include role::mobileapps
    include role::mathoid
    include role::graphoid
    include role::citoid
    include role::cxserver
    include role::changeprop

    include standard
    include base::firewall
    if $::realm == 'production' {
        include lvs::realserver
    }
}
