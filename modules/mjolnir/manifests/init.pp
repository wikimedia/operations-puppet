# SPDX-License-Identifier: Apache-2.0
# = Class: mjolnir
#
# This class installs the MjoLniR (Machine Learned Ranking) data
# processing package.
#
class mjolnir(
    String $logstash_host,
    Stdlib::Port $logstash_port
) {

    ensure_packages(['virtualenv', 'zip', 'python3-swiftclient', 'libsnappy1v5'])

    file { '/etc/mjolnir':
        ensure => 'directory',
        owner  => 'deploy-service',
        group  => 'deploy-service',
        mode   => '0755',
    }

    file { '/etc/mjolnir/logging_config.yaml':
        ensure  => 'file',
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        content => template('mjolnir/logging_config.yaml.erb')
    }

    scap::target { 'search/mjolnir/deploy':
        deploy_user => 'deploy-service',
        require     => Package['python3.7'],
    }
}
