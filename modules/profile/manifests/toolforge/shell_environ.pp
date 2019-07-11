# This class sets up a node as a shell dev environment for Toolforge.
#
# Those are the dependencies for development tools and packages intended
# for interactive use in a shell.  Most actual libraries are in exec_environ.

class profile::toolforge::shell_environ {
    class {'::phabricator::arcanist': } # T139738

    if os_version('debian jessie') {
        include profile::toolforge::genpp::python_dev_jessie
        package {'mytop':                   # T58999
            ensure  => latest,
        }
    } elsif os_version('debian stretch') {
        include profile::toolforge::genpp::python_dev_stretch
    }

    package { [
        'apt-file',
        'byobu',                       # T88989.
        'cvs',  # Because I don't think webhooks or other uses exist anymore outside cli
        'dh-make-perl',
        'elinks',
        'emacs',
        'fakeroot', # for dpkg
        'fish',                        # T219054
        'flex',                        # T114003.
        'ipython',                     # T58995
        'joe',                         # T64236.
        'links',
        'lintian',
        'lynx',
        'mc', # Popular{{cn}} on Toolserver
        'pastebinit',
        'pep8',                        # T59863
        'redis-tools',
        'rlwrap',                      # T87368
        'tig',
        'valgrind',                    # T87117.
    ]:
        ensure => latest,
    }

    # pastebinit configuration for https://tools.wmflabs.org/paste/.
    file { '/etc/pastebin.d':
        ensure  => 'directory',
        require => Package['pastebinit'],
        owner   => 'root',
        group   => 'root',
        mode    => '0555',
    }

    file { '/etc/pastebin.d/tools.conf':
        ensure  => 'file',
        require => File['/etc/pastebin.d'],
        source  => 'puppet:///modules/profile/toolforge/pastebinit.conf',
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
    }
}
