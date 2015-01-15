# "Compendium" class for nodes supporting various parsoid services
class role::sca {
    include role::apertium, role::citoid, role::cxserver, role::mathoid
    include standard
    include admin
    include lvs::realserver
    include base::firewall
}
