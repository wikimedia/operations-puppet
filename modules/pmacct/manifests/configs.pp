# pmacct::makeconfig
# Generates a unique config file per device and pretag file.

define pmacct::configs ($name, $port, $ip, $samplerate) {
    # Single confile file per device
    file { "/etc/pmacct/config-${name}.cfg":
        ensure  => 'file',
        owner   => 'pmacct',
        group   => 'pmacct',
        mode    => '0440',
        content => template('pmacct/config.erb'),
        require => File ['/etc/pmacct'],
    }

    # Populate pretag file
    file_line { "Port ${port} IP ${ip}":
        line    => "set_tag=${port} ip=${ip}",
        path    => '/etc/pmacct/pretag.map',
        require => File['/etc/pmacct/pretag.map'],
    }

    # Corresponding ferm rule for bgp redirects
    ferm::rule {"pmacct_${name}_bgp_redirect":
        domain => '(ip)',  # ipv6 doesn't have a 'nat' table
        prio   => '20',
        rule   => "proto tcp dport 179 source ${ip} REDIRECT to-ports ${port};",
        table  => 'nat',
        chain  => 'PREROUTING',
    }
}
