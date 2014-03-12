# Class: pmacct::install
#
# This installs and mangages pmacct configuration
# http://www.pmacct.net/
class pmacct::install ($home='/home/pmacct') {

    # Package
    # Must be built with these configure flags
    # --enable-mysql --enable-64bit --enable-threads --enable-geoip
    package { 'pmacct':
        ensure => installed,
    }

    # User creation (not done by package)
    generic::systemuser { 'pmacct':
        name  => 'pmacct',
        home  => $home,
        shell => '/bin/bash',
    }

    # Home directory
    file { $home:
        ensure => 'directory',
        owner  => 'pmacct',
        group  => 'pmacct',
        mode   => '0750',
    }

    # Log directory
    file { "${home}/logs":
        ensure  => 'directory',
        owner   => 'pmacct',
        group   => 'pmacct',
        mode    => '0750',
        require => File[ $home ],
    }

    # Config directory
    file { "${home}/configs":
        ensure  => 'directory',
        owner   => 'pmacct',
        group   => 'pmacct',
        mode    => '0750',
        require => File[ $home ],
    }

    # Pretag map file
    file { "${home}/configs/pretag.map":
      ensure  => present,
      owner   => 'pmacct',
      group   => 'pmacct',
      mode    => '0640',
    }

}
