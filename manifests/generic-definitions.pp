# generic-definitions.pp
#
# File that contains generally useful definitions.
# e.g. for creating system users

# Enables a certain Apache 2 site
define apache_site(
    $name,
    $prefix = '',
    $ensure = 'link',
) {

    file { "/etc/apache2/sites-enabled/${prefix}${name}":
        ensure => $ensure,
        target => "/etc/apache2/sites-available/${name}",
    }
}

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
