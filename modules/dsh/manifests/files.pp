# creates config files for dsh
class dsh::files {

    file {
        '/etc/dsh':
            ensure  => directory,
            owner   => 'root',
            group   => 'root',
            mode    => '0444';
        '/etc/dsh/group':
            owner   => 'root',
            group   => 'root',
            mode    => '0444',
            source  => 'puppet:///modules/dsh/group',
            recurse => true;
        '/etc/dsh/dsh.conf':
            owner   => 'root',
            group   => 'root',
            mode    => '0444',
            source  => 'puppet:///modules/dsh/dsh.conf';
    }

}
