# "Compendium" class for nodes supporting various *oid services
# This class is an intermediate step to better design
class role::scb {

    $services = [
        'ORES', 'changeprop', 'citoid', 'cpjobqueue', 'cxserver',
        'eventstreams', 'graphoid', 'mathoid', 'mobileapps',
        'pdfrender', 'trendingedits',
    ]
    $msg_services = join($services, "\n\t")

    system::role { 'scb':
        description => "Service cluster B; includes:\n\t${msg_services}"
    }

    include ::standard
    include ::profile::base::firewall
    include role::lvs::realserver

    # Ores
    include ::profile::ores::worker
    include ::profile::ores::web
    include ::profile::nutcracker


    include ::profile::cpjobqueue
    include ::profile::recommendation_api
    include ::profile::mobileapps
    include ::profile::mathoid
    include ::profile::graphoid
    include ::profile::citoid
    include ::profile::cxserver
    include ::profile::changeprop
    include ::profile::apertium
    include ::profile::eventstreams
    include ::profile::pdfrender
    include ::profile::trendingedits
}
