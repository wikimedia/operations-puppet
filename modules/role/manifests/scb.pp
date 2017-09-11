# "Compendium" class for nodes supporting various *oid services
# This class is an intermediate step to better design
class role::scb {
    include ::profile::ores::worker
    include ::profile::ores::web
    include ::profile::nutcracker

    include ::profile::cpjobqueue
    system::role { 'cpjobqueue':
        description => 'ChangeProp instance for the JobQueue',
    }

    include ::profile::recommendation_api

    include role::mobileapps
    include role::mathoid
    include role::graphoid
    include role::citoid
    include role::cxserver
    include role::changeprop
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
