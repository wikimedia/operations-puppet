# == Class profile::analytics::cluster::secrets
#
# Creates protected files in HDFS that contains
# credentials used to access MySQL slaves, Swift, etc.
# This is so we can automate sqooping of data
# out of MySQL into Hadoop and uploading into Swift.
#
# == Parameters
# [*use_kerberos*]
#   If true, exec commands will be wrapped to kinit with kerberos.
#
# [*swift_group*]
#   Group that the swift auth env file should be group owned by.
#   This group must already exist on the node.
#   Default: analytics-privatedata-users
class profile::analytics::cluster::secrets(
    $use_kerberos       = hiera('profile::analytics::cluster::secrets::use_kerberos', false),
    $swift_group        = hiera('profile::analytics::cluster::secrets::swift_group', 'analytics-privatedata-users'),
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
        command      => "/bin/echo -n '${research_pass}' | /usr/bin/hdfs dfs -put - ${research_path} && /usr/bin/hdfs dfs -chmod 600 ${research_path} && /usr/bin/hdfs dfs -chown ${secrets_user}:${secrets_group} ${research_path}",
        unless       => "/usr/bin/hdfs dfs -test -e ${research_path}",
        user         => $secrets_user,
        use_kerberos => $use_kerberos,
    }

    # mysql labsdb analytics user creds
    include ::passwords::mysql::analytics_labsdb
    $labsdb_user = $::passwords::mysql::analytics_labsdb::user
    $labsdb_pass = $::passwords::mysql::analytics_labsdb::pass
    $labsdb_path = "/user/${secrets_user}/mysql-analytics-labsdb-client-pw.txt"
    kerberos::exec { 'hdfs_put_mysql-analytics-labsdb-client-pw.txt':
        command      => "/bin/echo -n '${labsdb_pass}' | /usr/bin/hdfs dfs -put - ${labsdb_path} && /usr/bin/hdfs dfs -chmod 600 ${labsdb_path} && /usr/bin/hdfs dfs -chown ${secrets_user}:${secrets_group} ${labsdb_path}",
        unless       => "/usr/bin/hdfs dfs -test -e ${labsdb_path}",
        user         => $secrets_user,
        use_kerberos => $use_kerberos,
    }

    # Swift objectstore analytics_admin credentials.
    # Unfortunetly this still comes from class scope hiera rather than profile/role hiera.
    # lint:ignore:wmf_styleguide
    include ::swift::params
    # lint:endignore
    $swift_accounts     = $::swift::params::accounts
    $swift_account_keys = $::swift::params::account_keys

    $swift_analytics_admin_auth_url = "${swift_accounts['analytics_admin']['auth']}/auth/v1.0"
    $swift_analytics_admin_user     = $swift_accounts['analytics_admin']['user']
    $swift_analytics_admin_key      = $swift_account_keys['analytics_admin']
    $swift_analytics_admin_auth_env_content = "export ST_AUTH=${swift_analytics_admin_auth_url}/auth/v1.0\nexport ST_USER=${swift_analytics_admin_user}\nexport ST_KEY=${swift_analytics_admin_key}\n"
    $swift_analytics_admin_auth_env_path    = "/user/${secrets_user}/swift_auth_analytics_admin.env"
    kerberos::exec { 'hdfs_put_swift_auth_analytics_admin.env':
        command      => "/bin/echo -n '${swift_analytics_admin_auth_env_content}' | /usr/bin/hdfs dfs -put - ${swift_analytics_admin_auth_env_path} && /usr/bin/hdfs dfs -chmod 600 ${swift_analytics_admin_auth_env_path} && /usr/bin/hdfs dfs -chown ${secrets_user}:${swift_group} ${swift_analytics_admin_auth_env_path}",
        unless       => "/usr/bin/hdfs dfs -test -e ${swift_analytics_admin_auth_env_path}",
        user         => $secrets_user,
        use_kerberos => $use_kerberos,
    }

}
