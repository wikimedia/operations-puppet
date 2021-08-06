# lint:ignore:wmf_styleguide
# filtertags: labs-project-deployment-prep
#
# Ignore style violations because of temporary nature of this role.
#
# This is a hack to be able to test dragonfly P2P distribution with multiple nodes.
class role::mediawiki::appserver_dragonfly {
    include role::mediawiki::appserver

    # Install docker and set up credentials
    ensure_packages(['docker.io'], {'ensure' => 'purged'})
    file { '/root/.docker/config.json':
        ensure => absent,
    }

    # Setup dfdaemon and configure docker to use it
    include profile::dragonfly::dfdaemon
}
# lint:endignore
