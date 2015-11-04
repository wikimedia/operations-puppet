# "Compendium" class for nodes supporting various *oid services
# This class is an intermediate step to better design
class role::sca {
    include role::apertium
    include role::citoid
    include role::cxserver
    include role::mathoid
    include role::zotero
    include role::graphoid
    include role::cxserver

    include standard
    include base::firewall
    if $::realm == 'production' {
        include lvs::realserver
    }
}
