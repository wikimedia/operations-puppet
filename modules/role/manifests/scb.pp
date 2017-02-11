# "Compendium" class for nodes supporting various *oid services
# This class is an intermediate step to better design
class role::scb {
    include role::mobileapps
    include role::mathoid
    include role::graphoid
    include role::citoid
    include role::cxserver
    include role::changeprop
    include role::ores::web
    include role::ores::worker
    include role::apertium
    include role::eventstreams
    include role::pdfrender
    include role::trendingedits

    include ::standard
    include ::base::firewall

    if hiera('has_lvs', true) {
        include role::lvs::realserver
    }
}
