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
    ensure_packages(['python3-attr', 'python3-clustershell', 'python3-jsonschema',
                    'python3-requests', 'python3-requests-toolbelt', 'python3-yaml'])

    git::clone { 'operations/software/httpbb':
        directory => $install_dir,
        branch    => 'master',
    }

    file { '/usr/local/bin/httpbb':
        ensure  => file,
        content => "#!/bin/sh\ncd ${install_dir}\npython3 -m httpbb.main \"$@\"",
        owner   => 'root',
        group   => 'root',
        mode    => '0555',
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
