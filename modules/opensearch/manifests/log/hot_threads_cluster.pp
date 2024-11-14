# SPDX-License-Identifier: Apache-2.0
# == Define: opensearch::log::hot_threads_cluster
#
# Configure an opensearch instance to collect hot threads logs.
#
define opensearch::log::hot_threads_cluster(
    Stdlib::Port $http_port,
    String $cluster_name = $title,
){
    include ::opensearch::log::hot_threads

    file { "/etc/opensearch_hot_threads.d/${cluster_name}.yml":
        ensure  => file,
        owner   => 'root',
        group   => 'root',
        mode    => '0755',
        content => to_yaml({
            port     => $http_port,
            log_file => "/var/log/opensearch/opensearch_hot_threads-${cluster_name}.log",
        }),
    }
}
