# pmacct::makeconfig
# Generates a unique config file per device and pretag file.

define pmacct::configs ($name, $port, $ip, $samplerate) {
    # Single confile file per device
    file { "${pmacct::home}/configs/config-${name}.cfg":
        ensure  => 'file',
        owner   => 'pmacct',
        group   => 'pmacct',
        mode    => '0640',
        content => template('pmacct/config.erb'),
        require => File [ "${pmacct::home}/configs" ],
    }

    # Populate pretag file
    file_line { "Port ${port}":
      line => "set_tag=${port} ip=${ip}",
      path => "${pmacct::home}/configs/pretag.map",
    }

    # Corresponding ferm rule for firewall redirect
    ferm::rule {"${name}-BGP":
        rule  => "proto tcp dport 179 source ${ip} REDIRECT to-ports ${port}",
        table => 'nat',
        chain => 'PREROUTING',
    }
}
