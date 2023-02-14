# lvs/balancer/runcommand.pp

# Supporting the PyBal RunCommand monitor
class lvs::balancer::runcommand {

    file {
        '/etc/pybal/runcommand':
            ensure => directory,
            mode   => '0755';
    }
}
