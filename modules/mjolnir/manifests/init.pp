# = Class: mjolnir
#
# This class installs the MjoLniR (Machine Learned Ranking) data
# processing package.
#
class mjolnir(
    String $logstash_host,
    Wmflib::IpPort $logstash_port
) {
    require_package('virtualenv', 'zip', 'libsnappy1v5')

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
    }
}
