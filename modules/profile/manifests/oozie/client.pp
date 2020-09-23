# == Class profile::oozie::client
#
class profile::oozie::client(
    Stdlib::Host $oozie_host = lookup('profile::oozie::client::oozie_host'),
) {
    class { '::cdh::oozie':
        oozie_host => $oozie_host,
    }
}
