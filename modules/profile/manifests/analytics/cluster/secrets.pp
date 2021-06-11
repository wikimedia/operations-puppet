# == Class profile::analytics::cluster::secrets
#
# Creates protected files in HDFS that contains
# credentials used to access MySQL replicas, Swift, etc.
# This is so we can automate sqooping of data
# out of MySQL into Hadoop and uploading into Swift.
#
# == Parameters
#
# [*swift_group*]
#   Group that the swift auth env file should be group owned by.
#   This group must already exist on the node.
#
# [*swift_accounts*]
#   The accounts map to use for swift.
#
# [*swift_accounts_keys*]
#   The accounts keys map to use for swift.
class profile::analytics::cluster::secrets(
    String $swift_group = lookup('profile::analytics::cluster::secrets::swift_group', {'default_value' => 'analytics-privatedata-users'}),
    Hash[String, Hash[String, String]] $swift_accounts = lookup('profile::swift::accounts'),
    Hash[String, String] $swift_account_keys = lookup('profile::swift::accounts_keys'),
) {
    require ::profile::hadoop::common

    $secrets_user = 'analytics'
    $secrets_group = 'analytics'

    # Make sure something has declared the $secrets_user
    User[$secrets_user] -> Class['profile::analytics::cluster::secrets']

    # mysql research user creds
    include ::passwords::mysql::research
    $research_user = $::passwords::mysql::research::user
    $research_pass = $::passwords::mysql::research::pass
    $research_path = "/user/${secrets_user}/mysql-analytics-research-client-pw.txt"

    kerberos::exec { 'hdfs_put_mysql-analytics-research-client-pw.txt':
        command => "/bin/echo -n '${research_pass}' | /usr/bin/hdfs dfs -put - ${research_path} && /usr/bin/hdfs dfs -chmod 600 ${research_path} && /usr/bin/hdfs dfs -chown ${secrets_user}:${secrets_group} ${research_path}",
        unless  => "/usr/bin/hdfs dfs -test -e ${research_path}",
        user    => $secrets_user,
    }

    # mysql clouddb1021 analytics user creds
    include ::passwords::mysql::analytics_labsdb
    $labsdb_user = $::passwords::mysql::analytics_labsdb::user
    $labsdb_pass = $::passwords::mysql::analytics_labsdb::pass
    $labsdb_path = "/user/${secrets_user}/mysql-analytics-labsdb-client-pw.txt"
    kerberos::exec { 'hdfs_put_mysql-analytics-labsdb-client-pw.txt':
        command => "/bin/echo -n '${labsdb_pass}' | /usr/bin/hdfs dfs -put - ${labsdb_path} && /usr/bin/hdfs dfs -chmod 600 ${labsdb_path} && /usr/bin/hdfs dfs -chown ${secrets_user}:${secrets_group} ${labsdb_path}",
        unless  => "/usr/bin/hdfs dfs -test -e ${labsdb_path}",
        user    => $secrets_user,
    }

    $swift_analytics_admin_auth_url = "${swift_accounts['analytics_admin']['auth']}/auth/v1.0"
    $swift_analytics_admin_user     = $swift_accounts['analytics_admin']['user']
    $swift_analytics_admin_key      = $swift_account_keys['analytics_admin']
    $swift_analytics_admin_auth_env_content = "export ST_AUTH=${swift_analytics_admin_auth_url}/auth/v1.0\nexport ST_USER=${swift_analytics_admin_user}\nexport ST_KEY=${swift_analytics_admin_key}\n"
    $swift_analytics_admin_auth_env_path    = "/user/${secrets_user}/swift_auth_analytics_admin.env"
    kerberos::exec { 'hdfs_put_swift_auth_analytics_admin.env':
        command => "/bin/echo -n '${swift_analytics_admin_auth_env_content}' | /usr/bin/hdfs dfs -put - ${swift_analytics_admin_auth_env_path} && /usr/bin/hdfs dfs -chmod 640 ${swift_analytics_admin_auth_env_path} && /usr/bin/hdfs dfs -chown ${secrets_user}:${swift_group} ${swift_analytics_admin_auth_env_path}",
        unless  => "/usr/bin/hdfs dfs -test -e ${swift_analytics_admin_auth_env_path}",
        user    => $secrets_user,
    }

}
