# == Class role::analytics_cluster::mysql_password
# Creates a protected file in HDFS that contains
# a password used to access the MySQL research slaves.
# This is so we can automate sqooping of data
# out of MySQL into Hadoop.
#
# This will put the $::passwords::mysql::research::pass
# at hdfs:///user/hdfs/mysql-analytics-research-client-pw.txt
#
class role::analytics_cluster::mysql_password {
    Class['role::analytics_cluster::hadoop::client'] -> Class['role::analytics_cluster::mysql_password']

    include ::passwords::mysql::research
    $password = $::passwords::mysql::research::pass
    $path     = '/user/hdfs/mysql-analytics-research-client-pw.txt'

    exec { 'hdfs_put_mysql-analytics-research-client-pw.txt':
        command => "/bin/echo -n '${password}' | /usr/bin/hdfs dfs -put - ${path} && /usr/bin/hdfs dfs -chmod 600 ${path}",
        unless  => "/usr/bin/hdfs dfs -test -e ${path}",
        user    => 'hdfs',
    }
}
