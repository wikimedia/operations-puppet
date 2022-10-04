# SPDX-License-Identifier: Apache-2.0
define k8s::kubeconfig (
    String $master_host,
    String $username,
    String $token,
    String $owner='root',
    String $group='root',
    Stdlib::Filemode $mode='0400',
    Optional[String] $namespace=undef,
    Wmflib::Ensure $ensure = present,
) {
    require k8s::base_dirs
    file { $title:
        ensure  => $ensure,
        content => template('k8s/kubeconfig-client.yaml.erb'),
        owner   => $owner,
        group   => $group,
        mode    => $mode,
    }
}
