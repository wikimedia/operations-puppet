# == Class: puppetmaster::hiera
#
# Configures the HIERArchical configuration system for puppet
#
# == Parameters
#
# [*config*]
# The configuration file source (must be contained in the puppetmaster
# module). If undef, the file will just be created empty.
#

class puppetmaster::hiera ( $ensure = 'present', $config = undef) {
    if $config != undef {
        $config = "puppet:///modules/puppetmaster/${config}"
    }

    file { '/etc/puppet/hiera.yaml':
        ensure  => $ensure,
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        source  => $config,
        require => Package['puppetmaster-common']
    }
    # We don't need to declare ruby-hiera as a package explicitly as
    # puppetmaster-common depends on ruby-hiera.
}
