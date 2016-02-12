# == Class role::analytics::oozie::config
#
class role::analytics::oozie::config {
    include role::analytics::hadoop::config

    if $::realm == 'production' {
        include passwords::analytics

        $jdbc_password      = $passwords::analytics::oozie_jdbc_password
        # Must set oozie_host in hiera in production.
        $default_oozie_host = undef

    }
    elsif $::realm == 'labs' {
        $jdbc_password      = 'oozie'
        # Default to running oozie server on primary namenode in labs.
        $default_oozie_host = $role::analytics::hadoop::config::namenode_hosts[0]
    }

    $oozie_host = hiera('oozie_host', $default_oozie_host)
}
