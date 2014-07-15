class mediawiki {
    include ::mediawiki::users
    include ::mediawiki::sync
    include ::mediawiki::cgroup
    include ::mediawiki::packages
    include ::ssh::server

    file { '/etc/cluster':
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        content => $::site,
    }

    if $::realm == 'labs' {
        $mw_mc_server_list = [
            '10.68.16.14:11211', # deployment-memc02.eqiad.wmflabs
            '10.68.16.15:11211', # deployment-memc03.eqiad.wmflabs
        ]
    } else {
        $mw_mc_server_list = [
            '10.64.0.180:11211', # mc1001
            '10.64.0.181:11211', # mc1002
            '10.64.0.182:11211', # mc1003
            '10.64.0.183:11211', # mc1004
            '10.64.0.184:11211', # mc1005
            '10.64.0.185:11211', # mc1006
            '10.64.0.186:11211', # mc1007
            '10.64.0.187:11211', # mc1008
            '10.64.0.188:11211', # mc1009
            '10.64.0.189:11211', # mc1010
            '10.64.0.190:11211', # mc1011
            '10.64.0.191:11211', # mc1012
            '10.64.0.192:11211', # mc1013
            '10.64.0.193:11211', # mc1014
            '10.64.0.194:11211', # mc1015
            '10.64.0.195:11211', # mc1016
        ]
    }

    class { '::nutcracker':
        server_list => $mw_mc_server_list,
    }

    # Increase scheduling priority of SSHD
    file { '/etc/init/ssh.override':
        content => "nice -10\n",
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        notify  => Service['ssh'],
    }
}
