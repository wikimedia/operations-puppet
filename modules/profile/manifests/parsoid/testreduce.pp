class profile::parsoid::testreduce(
    Boolean $install_node = lookup('profile::parsoid::testreduce::install_node'),
){
    class { 'testreduce':
        install_node => $install_node,
    }
}
