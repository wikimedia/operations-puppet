# == Define: elasticsearch::log::hot_threads_cluster
#
# Configure an elasticsearch instance to collect hot threads logs.
#
define elasticsearch::log::hot_threads_cluster(
    Stdlib::Port $http_port,
    String $cluster_name = $title,
){
    include ::elasticsearch::log::hot_threads

    file { "/etc/elasticsearch_hot_threads.d/${cluster_name}.yml":
        ensure  => file,
        owner   => 'root',
        group   => 'root',
        mode    => '0755',
        content => ordered_yaml({
            port     => $http_port,
            log_file => "/var/log/elasticsearch/elasticsearch_hot_threads-${cluster_name}.log",
        }),
    }
}
