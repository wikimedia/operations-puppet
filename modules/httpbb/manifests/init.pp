# == Class httpbb
#
# Installs the httpbb tool for blackbox testing an HTTP server.
#
# == Parameters
# - $install_dir: Directory to install the httpbb binary.
# - $tests_dir: Directory to install test suite YAML files, supplied as
#               httpbb::test_suite resources.
class httpbb(
    Stdlib::Unixpath $install_dir = '/srv/deployment/httpbb',
    Stdlib::Unixpath $tests_dir = '/srv/deployment/httpbb-tests',
){
    ensure_packages('httpbb')

    file { $install_dir:
        ensure => absent,
        force  => true,
    }

    file { '/usr/local/bin/httpbb':
        ensure => absent,
    }

    file { $tests_dir:
        ensure => directory,
    }

    # Little automation to use on the cumin masters for deploying an apache config change
    file { '/usr/local/bin/deploy-apache-change':
        ensure  => present,
        content => template('httpbb/deploy_apache_change.sh.erb'),
        owner   => 'root',
        group   => 'root',
        mode    => '0555',
    }
}
