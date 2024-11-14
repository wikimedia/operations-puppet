# SPDX-License-Identifier: Apache-2.0
# = Class: opensearch::keystore
#
# This define stores a single value into the opensearch keystore for the
# named instance.
#
# == Parameters
# $cluster_name: The name of the cluster to configure.
# $key: The name of the value to store in the keystore
# $value: The value to store in the keystore
define opensearch::keystore (
    String $cluster_name,
    String $key,
    String $value,
) {
    $config_dir = "/etc/opensearch/${cluster_name}"
    $keystore = '/usr/share/opensearch/bin/opensearch-keystore'

    exec { $title:
        command     => "echo '${value}' | ${keystore} add ${key}",
        environment => ["OPENSEARCH_PATH_CONF=${config_dir}"],
        group       => 'opensearch',
        require     => File["${config_dir}/opensearch.keystore"],
        path        => '/bin:/usr/bin',
        unless      => "${keystore} list | grep ${key}",
    }
}
