# pmacct::makeconfig
# Generates a unique config file per device

define pmacct::makeconfig ($name, $port, $ip, $samplerate) {
    # Single confile file per device
    file { "$pmacct::home/configs/config-${name}.cfg":
        ensure  => 'file',
        owner  => 'pmacct',
        group  => 'pmacct',
        mode   => '0750',
        content => template('pmacct/config.erb'),
        require => File [ "$pmacct::home/configs" ],
    }

    # Corresponding ferm rule for firewall redirect
    ferm::rule {"${name}-BGP":
        rule => "proto tcp dport 179 source ${ip} REDIRECT to-ports ${port}",
        table => 'nat',
        chain => 'PREROUTING',
    }
    
}
