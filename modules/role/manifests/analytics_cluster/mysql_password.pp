# == Class role::analytics_cluster::mysql_password
# Creates protected files in HDFS that contains
# a passwords used to access MySQL slaves.
# This is so we can automate sqooping of data
# out of MySQL into Hadoop.
#
class role::analytics_cluster::mysql_password {
    Class['role::analytics_cluster::hadoop::client'] -> Class['role::analytics_cluster::mysql_password']

    include ::passwords::mysql::research
    $research_user = $::passwords::mysql::research::user
    $research_pass = $::passwords::mysql::research::pass
    $research_path = '/user/hdfs/mysql-analytics-research-client-pw.txt'
    exec { 'hdfs_put_mysql-analytics-research-client-pw.txt':
        command => "/bin/echo -n '${research_pass}' | /usr/bin/hdfs dfs -put - ${research_path} && /usr/bin/hdfs dfs -chmod 600 ${research_path}",
        unless  => "/usr/bin/hdfs dfs -test -e ${research_path}",
        user    => 'hdfs',
    }

    include ::passwords::mysql::analytics_labsdb
    $labsdb_user = $::passwords::mysql::analytics_labsdb::user
    $labsdb_pass = $::passwords::mysql::analytics_labsdb::pass
    $labsdb_path = '/user/hdfs/mysql-analytics-labsdb-client-pw.txt'
    exec { 'hdfs_put_mysql-analytics-labsdb-client-pw.txt':
        command => "/bin/echo -n '${labsdb_pass}' | /usr/bin/hdfs dfs -put - ${labsdb_path} && /usr/bin/hdfs dfs -chmod 600 ${labsdb_path}",
        unless  => "/usr/bin/hdfs dfs -test -e ${labsdb_path}",
        user    => 'hdfs',
    }
}
