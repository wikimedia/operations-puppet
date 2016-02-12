# == Class role::analytics::hive::config
#
class role::analytics::hive::config {
    # require zookeeper config to get zookeeper hosts array.
    include role::analytics::hadoop::config

    # Set this pretty high, to avoid limiting the number
    # of substitution variables a Hive script can use.
    $variable_substitute_depth = 10000

    # The WMF webrequest table uses HCatalog's JSON Serde.
    # Automatically include this in Hive client classpaths.
    $hcatalog_jar = 'file:///usr/lib/hive-hcatalog/share/hcatalog/hive-hcatalog-core.jar'

    # If refinery is included on this node, then add
    # refinery-hive.jar to the auxpath as well
    if defined(Class['role::analytics::refinery']) {
        $auxpath = "${hcatalog_jar},file://${::role::analytics::refinery::path}/artifacts/refinery-hive.jar"
    }
    else {
        $auxpath = $hcatalog_jar
    }

    # Hive uses Zookeeper for table locking.
    $zookeeper_hosts = keys(hiera('zookeeper_hosts'))

    # We set support concurrency to false by default.
    # if someone needs to use it in their hive job, they
    # may manually set it to true via
    # set hive.support.concurrency = true;
    $support_concurrency = false

    if $::realm == 'production' {
        include passwords::analytics

        $jdbc_password   = $passwords::analytics::hive_jdbc_password
        # Must set hive_server_host and hive_metastore_host in hiera
        # in production.
        $default_hive_host = undef
    }
    elsif $::realm == 'labs' {
        $jdbc_password   = 'hive'
        # Default to hosting hive-server and hive-metastore on
        # primary namenode in labs.
        $default_hive_host = $role::analytics::hadoop::config::namenode_hosts[0]
    }

    $server_host     = hiera('hive_server_host', $default_hive_host)
    $metastore_host  = hiera('hive_metastore_host', $default_hive_host)
}
