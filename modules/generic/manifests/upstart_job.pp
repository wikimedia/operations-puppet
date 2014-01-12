# Create a symlink in /etc/init.d/ to a generic upstart init script
define generic::upstart_job($install=false, $start=false) {
    # Create symlink
    file { "/etc/init.d/${title}":
        ensure  => link,
        owner   => 'root',
        group   => 'root',
        target  => '/lib/init/upstart-job',
    }

    if $install == true {
        file { "/etc/init/${title}.conf":
            owner    => 'root',
            group   => 'root',
            mode    => '0444',
            source  => "puppet:///modules/generic/upstart/${title}.conf",
        }
    }

    if $start == true {
        exec { "start ${title}":
            require     => File["/etc/init/${title}.conf"],
            subscribe   => File["/etc/init/${title}.conf"],
            refreshonly => true,
            command     => "start ${title}",
            unless      => "status ${title} | grep -q start/running",
            path        => '/bin:/sbin:/usr/bin:/usr/sbin',
        }
    }
}
