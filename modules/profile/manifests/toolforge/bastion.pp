# This profile sets up an bastion/dev instance in the Toolforge model.
class profile::toolforge::bastion(
    $active_cronrunner = hiera('profile::toolforge::active_cronrunner'),
    String $dologmsg_prefix = lookup('dologmsg_prefix', {'default_value' => '#wikimedia-cloud !log '}),
    Stdlib::Host $dologmsg_host = lookup('dologmsg_host', {'default_value' => 'wm-bot2.wm-bot.eqiad.wmflabs'}),
    Stdlib::Port $dologmsg_port = lookup('dologmsg_port', {'default_value' => 64834}),
){
    # Son of Grid Engine Configuration
    # admin_host???
    include profile::toolforge::shell_environ
    include profile::toolforge::grid::exec_environ
    include profile::toolforge::k8s::client

    file { '/etc/toollabs-cronhost':
        ensure  => file,
        owner   => 'root',
        group   => 'root',
        mode    => '0644',
        content => $active_cronrunner,
    }
    file { '/usr/local/bin/crontab':
        ensure  => 'link',
        target  => '/usr/bin/oge-crontab',
        require => Package['misctools'],
    }

    file { '/usr/local/bin/killgridjobs.sh':
        ensure => file,
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
        source => 'puppet:///modules/profile/toolforge/gridscripts/killgridjobs.sh',
    }

    file { '/usr/local/sbin/qstat-full':
        ensure => absent,
    }

    file { '/usr/local/bin/qstat-full':
        ensure => file,
        owner  => 'root',
        group  => 'root',
        mode   => '0655',
        source => 'puppet:///modules/profile/toolforge/qstat-full',
    }

    file { "${profile::toolforge::grid::base::store}/submithost-${::fqdn}":
        ensure  => file,
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        require => File[$profile::toolforge::grid::base::store],
        content => "${::ipaddress}\n",
    }

    motd::script { 'bastion-banner':
        ensure => present,
        source => "puppet:///modules/profile/toolforge/40-${::labsproject}-bastion-banner.sh",
    }

    # Display tips.
    file { '/etc/profile.d/motd-tips.sh':
        ensure  => absent,
    }

    package { 'mosh':
        ensure => present,
    }

    # General SSH Use Configuration
    file { '/etc/ssh/ssh_config':
        ensure => file,
        owner  => 'root',
        group  => 'root',
        mode   => '0444',
        source => 'puppet:///modules/profile/toolforge/submithost-ssh_config',
    }

    # dologmsg to send log messages, configured using $dologmsg_* parameters
    file { '/usr/local/bin/dologmsg':
        ensure  => present,
        owner   => 'root',
        group   => 'root',
        mode    => '0555',
        content => template('profile/toolforge/dologmsg.erb'),
    }
}
