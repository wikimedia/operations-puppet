# == Class profile::hadoop::mysql_password
#
# Creates protected files in HDFS that contains
# a passwords used to access MySQL slaves.
# This is so we can automate sqooping of data
# out of MySQL into Hadoop.
#
class profile::hadoop::mysql_password(
    $use_kerberos = hiera('profile::hadoop::mysql_password::use_kerberos', false),
) {
    require ::profile::hadoop::common

    include ::passwords::mysql::research
    $research_user = $::passwords::mysql::research::user
    $research_pass = $::passwords::mysql::research::pass
    $research_path = '/user/hdfs/mysql-analytics-research-client-pw.txt'

    if $use_kerberos {
        File['/usr/local/bin/kerberos-puppet-wrapper'] -> Exec['hdfs_put_mysql-analytics-research-client-pw.txt']
        File['/usr/local/bin/kerberos-puppet-wrapper'] -> Exec['hdfs_put_mysql-analytics-labsdb-client-pw.txt']
        $wrapper = '/usr/local/bin/kerberos-puppet-wrapper hdfs '
    } else {
        $wrapper = ''
    }

    exec { 'hdfs_put_mysql-analytics-research-client-pw.txt':
        command => "/bin/echo -n '${research_pass}' | ${wrapper}/usr/bin/hdfs dfs -put - ${research_path} && ${wrapper}/usr/bin/hdfs dfs -chmod 600 ${research_path}",
        unless  => "${wrapper}/usr/bin/hdfs dfs -test -e ${research_path}",
        user    => 'hdfs',
    }

    include ::passwords::mysql::analytics_labsdb
    $labsdb_user = $::passwords::mysql::analytics_labsdb::user
    $labsdb_pass = $::passwords::mysql::analytics_labsdb::pass
    $labsdb_path = '/user/hdfs/mysql-analytics-labsdb-client-pw.txt'
    exec { 'hdfs_put_mysql-analytics-labsdb-client-pw.txt':
        command => "/bin/echo -n '${labsdb_pass}' | ${wrapper}/usr/bin/hdfs dfs -put - ${labsdb_path} && ${wrapper}/usr/bin/hdfs dfs -chmod 600 ${labsdb_path}",
        unless  => "${wrapper}/usr/bin/hdfs dfs -test -e ${labsdb_path}",
        user    => 'hdfs',
    }
}
