# SPDX-License-Identifier: Apache-2.0
class k8s::base_dirs {
    # TODO: This directory is created by kubernetes debian packages >= 1.23
    file { '/etc/kubernetes':
        ensure => directory,
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
    }
    # Ensure /etc/kubernetes/pki is created with generic read permissions as
    # multiple users will need to access certificates within.
    #
    # cfssl::cert does create this resource with more tight permissions
    # (based on the owner of the certificate) if not defined in advance.
    # FIXME: https://phabricator.wikimedia.org/T337826
    $cert_dir = '/etc/kubernetes/pki'
    unless defined(File[$cert_dir]) {
        file { $cert_dir:
            ensure => 'directory',
            owner  => 'root',
            group  => 'root',
            mode   => '0755',
        }
    }
}
