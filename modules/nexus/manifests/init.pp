class nexus (
    $data_dir
) {

    require_package('openjdk-8-jre-headless')

    group { 'nexus':
        ensure => present,
    }

    user { 'nexus':
        home       => '/var/lib/nexus',
        managehome => true,
        system     => true,
    }

    exec { 'create nexus data_dir':
        command => "/bin/mkdir -p ${data_dir}",
        creates => $data_dir,
    }
    file { $data_dir:
        ensure  => directory,
        user    => 'nexus',
        group   => 'nexus',
        require => Exec['create nexus data_dir'],
    }
}
