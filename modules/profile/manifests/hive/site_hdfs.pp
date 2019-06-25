# == Class profile::hive::site_hdfs
#
# Ensures latest /etc/hive/conf/hive-site.xml is in hdfs
#
# TODO: it would be much better if we had a nicer define or puppet function
# that would allow us to manage files in HDFS like we do in the regular
# filesystem.  If we figure that out, we can replace this class and also
# the analytics_cluster::mysql_password class.
#
class profile::hive::site_hdfs (
    $use_kerberos = hiera('profile::hive::site_hdfs::use_kerberos', false),
){
    Class['cdh::hive'] -> Class['profile::hive::site_hdfs']

    $hdfs_path = '/user/hive/hive-site.xml'
    # Put /etc/hive/conf/hive-site.xml in HDFS whenever puppet
    # notices that it has changed.
    kerberos::exec { 'put-hive-site-in-hdfs':
        command      => "/usr/bin/hdfs dfs -put -f ${cdh::hive::config_directory}/hive-site.xml ${hdfs_path} && /usr/bin/hdfs dfs -chmod 644 ${hdfs_path} && /usr/bin/hdfs dfs -chown hdfs:hdfs ${hdfs_path}",
        user         => 'hdfs',
        refreshonly  => true,
        subscribe    => File["${cdh::hive::config_directory}/hive-site.xml"],
        use_kerberos => $use_kerberos,
    }
}
