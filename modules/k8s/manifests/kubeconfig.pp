# SPDX-License-Identifier: Apache-2.0
# @summary
#   This class creates a kubernetes client configuration file.
#   Authentication is done by token or client certificate.
#
# === Parameters
# @param master_host
#   Hostname of the kubernetes master/apiserver
# @param username
#   Username
# @param token
#   The token to use for authentication (must be provided if auth_cert is not)
# @param auth_cert
#   The auth_cert to use for authentication (must be provided if token is not)
#   as returned by profile::pki::get_cert()
# @param owner
#   Owner of the file
# @param group
#   Group of the file
# @param mode
#   Permissions of the file
# @param namespace
#   A optional default kubernetes namespace

define k8s::kubeconfig (
    Stdlib::Fqdn $master_host,
    String $username,
    Optional[String] $token = undef,
    Optional[Hash[String, Stdlib::Unixpath]] $auth_cert = undef,
    String $owner = 'root',
    String $group = 'root',
    Stdlib::Filemode $mode = '0400',
    Optional[String] $namespace = undef,
    Wmflib::Ensure $ensure = present,
) {
    if $token == undef and $auth_cert == undef {
        fail('either token or auth_cert is required')
    } elsif $token != undef and $auth_cert != undef {
        fail('token and auth_cert are mutually exclusive parameters')
    }

    require k8s::base_dirs
    file { $title:
        ensure  => $ensure,
        content => template('k8s/kubeconfig-client.yaml.erb'),
        owner   => $owner,
        group   => $group,
        mode    => $mode,
    }
}
