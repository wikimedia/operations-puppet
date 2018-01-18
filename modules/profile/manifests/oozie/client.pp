# == Class profile::oozie::client
#
class profile::oozie::client(
    $oozie_host = hiera('profile::oozie::client::oozie_host'),
    $java_home  = hiera('profile::oozie::java_home', undef)
) {
    class { '::cdh::oozie':
        oozie_host => $oozie_host,
        java_home  => $java_home,
    }
}