class debdeploy::master {

    package { 'debdeploy-master':
        ensure => latest,
    }

    file {
        '/etc/debdeploy.conf':
            mode    => '0444',
            owner   => 'root',
            group   => 'root',
            content => template('debdeploy/debdeploy.erb');
    }
}
