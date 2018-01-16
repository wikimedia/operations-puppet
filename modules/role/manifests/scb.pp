# "Compendium" class for nodes supporting various *oid services
# This class is an intermediate step to better design
class role::scb {

    $services = [
        'ORES', 'changeprop', 'citoid', 'cpjobqueue', 'cxserver',
        'eventstreams', 'graphoid', 'mathoid', 'mobileapps',
        'pdfrender',
    ]
    $msg_services = join($services, "\n\t")

    system::role { 'scb':
        description => "Service cluster B; includes:\n\t${msg_services}"
    }

    include ::standard
    include ::base::firewall
    include role::lvs::realserver

    # Ores
    include ::profile::ores::worker
    include ::profile::ores::web
    include ::profile::nutcracker

    # Pin librdkfaka to specific version since node-rdkafka is built on it.
    # See: https://phabricator.wikimedia.org/T185016
    include ::profile::kafka::librdkafka::pin

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
}
