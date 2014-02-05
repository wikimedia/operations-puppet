# Packages that should only be on labs
#
class contint::packages::labs {

    if $::realm == 'production' {
        fail( 'contint::packages::labs must not be used in production' )
    }

    include contint::packages

    package { [
        'npm',
        'python-pip',

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

    # Bring tox/virtualenv... from pip  bug 44443
    package { 'tox':
        ensure   => present,
        provider => 'pip',
        require  => Package['python-pip'],
    }

}
