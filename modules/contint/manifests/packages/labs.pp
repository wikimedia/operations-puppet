# Packages that should only be on labs
#
class contint::packages::labs {

    if $::realm == 'production' {
        fail( 'contint::packages::labs must not be used in production' )
    }

    include contint::packages

    # Let us create packages from Jenkins jobs
    include misc::package-builder

    # Shell script wrappers to ease package building
    # Package generated via the mirror operations/debs/jenkins-debian-glue.git
    package { [
        'jenkins-debian-glue',
        'jenkins-debian-glue-buildenv',
        'jenkins-debian-glue-buildenv-git',
        'jenkins-debian-glue-buildenv-lintian',
        'jenkins-debian-glue-buildenv-piuparts',
        'jenkins-debian-glue-buildenv-taptools',
        ]:
            ensure  => latest,
            require => Class['misc::package-builder'],
    }

    package { [
        'npm',
        'python-pip',

        # Let us compile python modules:
        'python-dev',

        # For mediawiki/extensions/Collection/OfflineContentGenerator/bundler
        'zip',

        # For mediawiki/extensions/Collection/OfflineContentGenerator/latex_renderer
        # Provided by openstack::common:
        #'unzip',
        # provided by misc::contint::packages:
        #'librsvg2-bin',
        #'imagemagick',

        ]: ensure => present,
    }

    # Facebook Hiphop virtual machine
    package { 'hhvm': ensure => present }

    # Bring tox/virtualenv... from pip  bug 44443
    # TODO: Reevaluate this once we switch to trusty. Maybe provider being apt
    # would be better then
    package { 'tox':
        ensure   => present,
        provider => 'pip',
        require  => Package['python-pip'],
    }

    # puppet-lint to validate our Puppet manifests
    # TODO: Reevaluate this once we switch to trusty.
    package { 'rubygems':
        ensure => present,
    }
    package { 'puppet-lint':
        ensure   => present,
        provider => gem
        require  => Package['rubygems'],
    }

}
