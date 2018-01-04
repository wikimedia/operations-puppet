# Class: profile::druid::pivot
#
# Install and configure the Druid's Pivot nodejs UI
#
class profile::druid::pivot(
    $druid_broker = hiera('profile::druid::pivot::druid_broker'),
) {
    class { 'pivot':
        druid_broker => $druid_broker,
    }
}