define ntp::chrony($pool='', $permitted_networks=[]) {

    require_package('chrony')

    file { 'chrony.conf':
        mode    => '0644',
        owner   => 'root',
        group   => 'root',
        path    => '/etc/chrony/chrony.conf',
        content => template('ntp/chrony-conf.erb'),
    }

    service { 'chrony':
        ensure    => running,
        require   => File['chrony.conf'],
        subscribe => File['chrony.conf'],
    }
}
