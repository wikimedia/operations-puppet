# == Class role::analytics::oozie::client
# Installs Oozie client, which sets up the OOZIE_URL
# environment variable.  If you are using this class in
# Labs, you must include oozie::server on your primary
# Hadoop NameNode for this to work and set appropriate
# Labs Hadoop global parameters.
# See modules/role/manifests/analytics/hadoop/README.md documentation for more info.
class role::analytics::oozie::client inherits role::analytics::oozie::config {
    require role::analytics::hadoop::client

    class { 'cdh::oozie':
        oozie_host => $oozie_host,
    }
}
