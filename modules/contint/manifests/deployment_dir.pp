# == Class contint::deployment_dir
#
# Convenience class to create /srv/deployment/integration a popular place
# for our git clones / puppet software installations.
#
class contint::deployment_dir {
    include ::service::deploy::common
    if ! defined(File['/srv/deployment/integration']) {
        file { '/srv/deployment/integration':
            ensure => 'directory',
            mode   => '0755',
        }
    }
}
