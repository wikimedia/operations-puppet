class dumps::otherdumps::weekly::categoriesrdf (
    $user = undef,
) {
    file { '/var/log/categoriesrdf':
        ensure => 'directory',
        mode   => '0644',
        owner  => $user,
    }

    logrotate::conf { 'categoriesrdf':
        ensure => present,
        source => 'puppet:///modules/dumps/otherdumps/logrot/logrotate.categoriesrdf',
    }

    file { '/usr/local/bin/dumpcategoriesrdf.sh':
        mode   => '0755',
        owner  => 'root',
        group  => 'root',
        source => 'puppet:///modules/dumps/otherdumps/weeklies/dumpcategoriesrdf.sh',
    }
}
