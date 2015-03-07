# "Compendium" class for nodes supporting various *oid services
# This class is an intermediate step to better design
class role::sca {
    include role::apertium, role::citoid, role::cxserver, role::mathoid, role::zotero
    include standard
    include admin
    include lvs::realserver
    include base::firewall
}
