# generic-definitions.pp
#
# File that contains generally useful definitions.
# e.g. for creating system users
define apache_confd(
    $install= 'false',
    $enable = 'true',
    $ensure = 'present'
) {

    case $install {
        'true': {
            file { "/etc/apache2/conf.d/${name}":
                ensure => $ensure,
                source => "puppet:///files/apache/conf.d/${name}",
                mode   => '0444',
            }
        }
        'template': {
            file { "/etc/apache2/conf.d/${name}":
                ensure  => $ensure,
                content => template("apache/conf.d/${name}.erb"),
                mode    => '0444',
            }
        }
    }
}
