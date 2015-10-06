# lvs/balancer/runcommand.pp

# Supporting the PyBal RunCommand monitor
class lvs::balancer::runcommand {
    Class[lvs::balancer] -> Class[lvs::balancer::runcommand]

    file {
        '/etc/pybal/runcommand':
            ensure => 'directory',
            owner  => 'root',
            group  => 'root',
            mode   => '0755';
        '/etc/pybal/runcommand/check-apache':
            owner  => 'root',
            group  => 'root',
            mode   => '0555',
            source => "puppet:///modules/${module_name}/pybal/check-apache";
        '/root/.ssh/pybal-check':
            owner   => 'root',
            group   => 'root',
            mode    => '0600',
            content => secret('pybal/pybal-check');
    }
}
