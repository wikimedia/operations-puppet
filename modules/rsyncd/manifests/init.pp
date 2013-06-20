# Class: rsyncd
# Starts an rsyncd daemon.  Must specify either $config or $content.
#
# Usage:
#   class { "rsyncd": config => "home" }   # will put files/rsync/rsyncd.conf.home at /etc/rsyncd.conf
#   class { "rsyncd": content => template('udp2log/rsyncd.conf.erb) } # will render this .erb file at /etc/rsyncd.conf
#
# Parameters:
#   $config  - name of rsyncd.conf file to use from files/rsync/rsyncd.conf.$config
#   $content - content to render into /etc/rsyncd.conf
#
class rsyncd($config = undef, $content = undef) {

    package { "rsync":
        ensure => latest;
    }

    # rsync daemon defaults file
    file { "/etc/default/rsync":
        require => Package[rsync],
        mode    => 0644,
        owner   => root,
        group   => root,
        source  => "puppet:///modules/rsync/rsync.default",
        ensure  => present;
    }

    # rsyncd.conf, content either comes from source file or passed in content
    file { "/etc/rsyncd.conf":
        require => Package[rsync],
        mode    => 0644,
        owner   => root,
        group   => root,
        ensure  => present;
    }

    # if $config name was given, then use the file
    if $config {
        File["/etc/rsyncd.conf"] { source  => "puppet:///modules/rsync/rsyncd.conf.$config" }
    }
    # else if using $content, just render the given content
    elsif $content {
        File["/etc/rsyncd.conf"] { content  => $content }
    }
    # else alert an error
    else {
        alert("rsyncd '${title}' must specify one of \$config, \$content")
    }

    # start up the rsync daemon
    service { rsync:
        require   => [Package["rsync"], File["/etc/rsyncd.conf"], File["/etc/default/rsync"]],
        ensure    => running,
        subscribe => [File["/etc/rsyncd.conf"], File["/etc/default/rsync"]],
    }
}
