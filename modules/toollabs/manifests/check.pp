define toollabs::check (
    $path,
) {

    $check_name = $title

    # cheap way to ensure uniqueness across resources
    toollabs::check::path {$path: }

    file { "/etc/init/toolschecker/toolschecker_${check_name}.conf":
        ensure  => present,
        content => template('toollabs/toolschecker.upstart.erb'),
        owner   => 'root',
        group   => 'root',
        mode    => '0644',
        require => File['etc/init/toolschecker'],
        notify  => Service["toolschecker_${check_name}"],
    }

    service { "toolschecker_${check_name}":
        ensure  => running,
    }
}

# lint:ignore:autoloader_layout
define toollabs::check::path {
}

# lint:endignore
