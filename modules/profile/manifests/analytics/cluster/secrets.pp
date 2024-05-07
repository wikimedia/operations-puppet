# SPDX-License-Identifier: Apache-2.0
# == Class profile::analytics::cluster::secrets
#
# Creates protected files in HDFS that contains
# credentials used to access MySQL replicas, Swift, etc.
# This is so we can automate sqooping of data
# out of MySQL into Hadoop and uploading into Swift.
#
# Commands here are all run by the hdfs user, so this
# must be included on a node where the hdfs user exists
# and has a kerberos keytab.
#s
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
#
# [*swift_thanos_accounts*]
#   The accounts map to use for the thanos swift cluster.
#
# [*swift_thanos_accounts_keys*]
#   The accounts keys map to use for the thanos swift cluster.
#
class profile::analytics::cluster::secrets(
    String $swift_group = lookup('profile::analytics::cluster::secrets::swift_group', {'default_value' => 'analytics-privatedata-users'}),
    Hash[String, Hash[String, String]] $swift_accounts = lookup('profile::swift::accounts'),
    Hash[String, Hash] $global_swift_account_keys = lookup('profile::swift::global_account_keys'),
    Hash[String, Hash[String, String]] $swift_thanos_accounts = lookup('profile::thanos::swift::accounts'),
    Hash[String, String] $swift_thanos_account_keys = lookup('profile::thanos::swift::accounts_keys'),
) {
    require ::profile::hadoop::common

    # Get the local site's swift credentials
    $swift_account_keys = $global_swift_account_keys[$::site]

    $analytics_user = 'analytics'
    $analytics_group = 'analytics'

    # Make sure something has declared the $analytics_user
    User[$analytics_user] -> Class['profile::analytics::cluster::secrets']

    # mysql research user creds
    include ::passwords::mysql::research
    $research_user = $::passwords::mysql::research::user
    $research_pass = $::passwords::mysql::research::pass
    $research_path = "/user/${analytics_user}/mysql-analytics-research-client-pw.txt"

    kerberos::exec { 'hdfs_put_mysql-analytics-research-client-pw.txt':
        command => "/bin/echo -n '${research_pass}' | /usr/bin/hdfs dfs -put - ${research_path} && /usr/bin/hdfs dfs -chmod 600 ${research_path} && /usr/bin/hdfs dfs -chown ${analytics_user}:${analytics_group} ${research_path}",
        unless  => "/usr/bin/hdfs dfs -test -e ${research_path}",
        user    => 'hdfs',
    }

    $search_research_path = '/user/analytics-search/mysql-analytics-research-client-pw.txt'

    kerberos::exec { 'hdfs_put_mysql-analytics-search-research-client-pw.txt':
      command => "/bin/echo -ne '${research_user}\n${research_pass}' | /usr/bin/hdfs dfs -put - ${search_research_path} && /usr/bin/hdfs dfs -chmod 600 ${search_research_path} && /usr/bin/hdfs dfs -chown analytics-search:analytics-search ${search_research_path}",
      unless  => "/usr/bin/hdfs dfs -test -e ${search_research_path}",
      user    => 'hdfs',
    }

    $product_research_path = '/user/analytics-product/mysql-analytics-research-client-pw.txt'

    kerberos::exec { 'hdfs_put_mysql-analytics-product-research-client-pw.txt':
      command => "/bin/echo -ne '${research_pass}' | /usr/bin/hdfs dfs -put - ${product_research_path} && /usr/bin/hdfs dfs -chmod 600 ${product_research_path} && /usr/bin/hdfs dfs -chown analytics-product:analytics-privatedata-users ${product_research_path}",
      unless  => "/usr/bin/hdfs dfs -test -e ${product_research_path}",
      user    => 'hdfs',
    }

    # mysql clouddb1021 analytics user creds
    include ::passwords::mysql::analytics_labsdb
    $labsdb_user = $::passwords::mysql::analytics_labsdb::user
    $labsdb_pass = $::passwords::mysql::analytics_labsdb::pass
    $labsdb_path = "/user/${analytics_user}/mysql-analytics-labsdb-client-pw.txt"
    kerberos::exec { 'hdfs_put_mysql-analytics-labsdb-client-pw.txt':
        command => "/bin/echo -n '${labsdb_pass}' | /usr/bin/hdfs dfs -put - ${labsdb_path} && /usr/bin/hdfs dfs -chmod 600 ${labsdb_path} && /usr/bin/hdfs dfs -chown ${analytics_user}:${analytics_group} ${labsdb_path}",
        unless  => "/usr/bin/hdfs dfs -test -e ${labsdb_path}",
        user    => 'hdfs',
    }


    # Render the analytics_admin swift account Auth v1 env file for use by the analytics posix user.
    # https://phabricator.wikimedia.org/T294380
    # https://phabricator.wikimedia.org/T296945
    # See: https://docs.openstack.org/python-swiftclient/latest/cli/index.html
    $swift_analytics_admin_auth_url = "${swift_accounts['analytics_admin']['auth']}/auth/v1.0"
    $swift_analytics_admin_user     = $swift_accounts['analytics_admin']['user']
    $swift_analytics_admin_key      = $swift_account_keys['analytics_admin']
    $swift_analytics_admin_auth_env_content = "export ST_AUTH=${swift_analytics_admin_auth_url}\nexport ST_USER=${swift_analytics_admin_user}\nexport ST_KEY=${swift_analytics_admin_key}\n"
    $swift_analytics_admin_auth_env_path    = "/user/${analytics_user}/swift_auth_analytics_admin.env"
    kerberos::exec { 'hdfs_put_swift_auth_analytics_admin.env':
        command => "/bin/echo -n '${swift_analytics_admin_auth_env_content}' | /usr/bin/hdfs dfs -put - ${swift_analytics_admin_auth_env_path} && /usr/bin/hdfs dfs -chmod 640 ${swift_analytics_admin_auth_env_path} && /usr/bin/hdfs dfs -chown ${analytics_user}:${swift_group} ${swift_analytics_admin_auth_env_path}",
        unless  => "/usr/bin/hdfs dfs -test -e ${swift_analytics_admin_auth_env_path}",
        user    => 'hdfs',
    }

    # Render the research_poc thanos swift account Auth v1 env file for use by the analytics-research posix user.
    # https://phabricator.wikimedia.org/T294380
    # https://phabricator.wikimedia.org/T296945
    # See: https://docs.openstack.org/python-swiftclient/latest/cli/index.html

    # This user must have an HDFS account and have an HDFS /user home directory.
    # This can be done by making sure it is in one of the profile::hadoop::master::hadoop_user_groups.
    $analytics_research_user  = 'analytics-research'
    $analytics_research_group = 'analytics-research'

    $swift_research_poc_auth_url = "${swift_thanos_accounts['research_poc']['auth']}/auth/v1.0"
    $swift_research_poc_user     = $swift_thanos_accounts['research_poc']['user']
    $swift_research_poc_key      = $swift_thanos_account_keys['research_poc']
    $swift_research_poc_auth_env_content = "export ST_AUTH=${swift_research_poc_auth_url}\nexport ST_USER=${swift_research_poc_user}\nexport ST_KEY=${swift_research_poc_key}\n"
    $swift_research_poc_auth_env_path    = "/user/${analytics_research_user}/swift_auth_research_poc.env"
    kerberos::exec { 'hdfs_put_swift_auth_research_poc.env':
        command => "/bin/echo -n '${swift_research_poc_auth_env_content}' | /usr/bin/hdfs dfs -put - ${swift_research_poc_auth_env_path} && /usr/bin/hdfs dfs -chmod 440 ${swift_research_poc_auth_env_path} && /usr/bin/hdfs dfs -chown ${analytics_research_user}:${analytics_research_group} ${swift_research_poc_auth_env_path}",
        unless  => "/usr/bin/hdfs dfs -test -e ${swift_research_poc_auth_env_path}",
        user    => 'hdfs',
    }

}
