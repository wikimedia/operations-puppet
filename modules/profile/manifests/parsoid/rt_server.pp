# Parsoid RT testing services

# This instantiates testreduce::server
class profile::parsoid::rt_server (
    Stdlib::Ensure::Service $service_ensure = lookup('profile::parsoid::rt_server::service_ensure'),
){
    include ::testreduce
    include ::passwords::testreduce::mysql

    testreduce::server { 'parsoid-rt':
        instance_name  => 'parsoid-rt',
        db_host        => 'm5-master.eqiad.wmnet',
        db_name        => 'testreduce',
        db_user        => 'testreduce',
        db_pass        => $passwords::testreduce::mysql::db_pass,
        service_ensure => $service_ensure,
    }

    base::service_auto_restart { 'parsoid-rt': }
}
