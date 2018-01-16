# == Class profile::kafka::librdkafka::pin
#
# TODO: hopefully we don't need this for long.
# See: https://phabricator.wikimedia.org/T185016
#
# == Parameters
#
# [*version*]
#   Apt preferences pin version for librdkafka.
#
class profile::kafka::librdkafka::pin(
    $version = hiera('profile::kafka::librdkafka::pin::version', '0.9.*'),
) {
    # https://phabricator.wikimedia.org/T185016
    # Need to keep librddkafka from upgrading until
    # node-rdkafka is rebuilt with later version,
    # and we are sure that version is compatible with
    # main kafka broker version (currently 0.9.0.1).
    apt::pin { 'librdkafka':
        package  => 'librdkafka*',
        pin      => "version ${version}",
        priority => '1002',
    }
}
