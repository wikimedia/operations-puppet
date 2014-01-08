# vim:sw=4 ts=4 sts=4 et:

# = Class: kibana
#
# This class installs/configures/manages the Kibana application.
#
class kibana() {
    # Trebuchet deployment
    deployment::target { 'kibana': }

    file { '/etc/kibana':
        ensure  => directory,
        mode    => '0755',
        owner   => 'root',
        group   => 'root',
    }

    file { '/etc/kibana/config.js':
        ensure  => present,
        mode    => '0444',
        owner   => 'root',
        group   => 'root',
        source  => 'puppet:///modules/kibana/config.js',
        require => File['/etc/kibana'],
    }
}
