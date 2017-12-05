# == Class profile::oozie::client
#
class profile::oozie::client(
    $oozie_host = hiera('profile::oozie::client::oozie_host'),
) {
    class { '::cdh::oozie':
        oozie_host => $oozie_host,
    }
}