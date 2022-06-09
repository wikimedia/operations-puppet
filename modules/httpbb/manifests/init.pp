# SPDX-License-Identifier: Apache-2.0
# == Class httpbb
#
# Installs the httpbb tool for blackbox testing an HTTP server.
#
# == Parameters
# - $tests_dir: Directory to install test suite YAML files, supplied as
#               httpbb::test_suite resources.
class httpbb(
    Stdlib::Unixpath $tests_dir = '/srv/deployment/httpbb-tests',
){
    ensure_packages('httpbb')

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
