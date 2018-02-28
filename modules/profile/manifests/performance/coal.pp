# This profile installs coal, which is a utility built/maintained by
# the performance team in order to collect decent median values
# for incoming RUM performance data.
#
#   Contact: performance-team@wikimedia.org
#
# Parameters:
#
#  [*coal_whisper_dir*]
#    Where coal whisper files are located.
#    Default: /var/lib/coal
#
class profile::performance::coal(
    $coal_whisper_dir = hiera('profile::performance::coal::coal_whisper_dir', '/var/lib/coal')
) {
    # Consumes from eventlogging, on the analytics kafka cluster
    $kafka_config  = kafka_config('jumbo-eqiad')
    $kafka_brokers = $kafka_config['brokers']['string']

    # Additional vars have defaults set in modules/coal/init.pp
    class { '::coal':
        kafka_brokers => $kafka_brokers,
        whisper_dir   => $coal_whisper_dir
    }
}