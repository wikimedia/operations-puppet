# lvs/balancer/runcommand.pp

# Supporting the PyBal RunCommand monitor
class lvs::balancer::runcommand {

    file {
        '/etc/pybal/runcommand':
            ensure => directory,
            mode   => '0755';
        '/etc/pybal/runcommand/check-apache':
            mode   => '0555',
            source => "puppet:///modules/${module_name}/pybal/check-apache";
        '/root/.ssh/pybal-check':
            mode      => '0600',
            content   => secret('pybal/pybal-check'),
            show_diff => false;
    }
}
