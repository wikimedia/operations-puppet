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

    # https://phabricator.wikimedia.org/T185016
    # Need to keep librddkafka from upgrading until
    # node-rdkafka is rebuilt with later version,
    # and we are sure that version is compatible with
    # main kafka broker version (currently 0.9.0.1).
    apt::pin { 'librdkafka1':
        package  => 'librdkafka1',
        pin      => 'version 0.9.*',
        priority => '1002',
        before   => Package['librdkafka1'],
    }

    include ::standard
    include ::base::firewall
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
}
