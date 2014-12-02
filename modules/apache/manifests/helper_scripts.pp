# helper scripts for apache changes
class apache::helper_scripts {

    file  { '/usr/local/bin/apache-fast-test':
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
        source => 'puppet:///modules/apache/apache-fast-test',
    }

}
