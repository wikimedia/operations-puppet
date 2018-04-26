# This profile installs coal, which is a utility built/maintained by
# the performance team in order to collect decent median values
# for incoming RUM performance data.
#
#   Contact: performance-team@wikimedia.org
#
# This profile gets included from modules/profile/manifests/performance/site.pp,
# which is included from modules/role/manifests/graphite/primary.pp
#
class profile::performance::coal() {
    # Consumes from eventlogging, on the jumbo-eqiad kafka cluster
    $kafka_config  = kafka_config('jumbo-eqiad')
    $kafka_brokers = $kafka_config['brokers']['string']

    # Additional vars have defaults set in modules/coal/init.pp
    class { '::coal' }
    class { '::coal::web':
        kafka_brokers => $kafka_brokers
    }
}