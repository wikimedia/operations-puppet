# == Class contint::deployment_dir
#
# Convenience class to create /srv/deployment/integration a popular place
# for our git clones / puppet software installations.
#
class contint::deployment_dir {
    # Hack: faking directories that Trebuchet would normally manage.
    # The integration project in labs does not use Trebuchet to manage these
    # packages, but in production we do.
    if ! defined(File['/srv/deployment']) {
        file { '/srv/deployment':
            ensure => 'directory',
            mode   => '0755',
        }
    }
    if ! defined(File['/srv/deployment/integration']) {
        file { '/srv/deployment/integration':
            ensure => 'directory',
            mode   => '0755',
        }
    }
}
