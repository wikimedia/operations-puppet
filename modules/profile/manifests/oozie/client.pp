# == Class profile::oozie::client
#
class profile::oozie::client(
    Hash[String, Any] $oozie_services = lookup('oozie_services'),
    String $oozie_service             = lookup('profile::oozie::client::oozie_service'),
) {
    class { '::bigtop::oozie':
        oozie_host => $oozie_services[$oozie_service]['oozie_host']
    }
}
