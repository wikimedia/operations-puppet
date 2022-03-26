# Establish the ability to do Host Based Auth from bastions to execs/webgrid

class profile::toolforge::grid::hba {
    $bastions = wmflib::class::hosts('profile::toolforge::bastion')
    $bastion_ips = $bastions.map |Stdlib::Fqdn $host| { ipresolve($host, 4) }

    file { '/etc/ssh/shosts.equiv':
        ensure  => file,
        content => template('profile/toolforge/grid/hba/shosts.equiv.erb'),
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
    }

    security::access::config { 'toolforge-hba':
        content => template('profile/toolforge/grid/hba/security.conf.erb'),
    }

    file { [
        '/usr/local/sbin/project-make-access',
        '/usr/local/sbin/project-make-shosts',
        '/etc/project.access',
        '/etc/ssh/shosts.equiv~'
    ]:
        ensure => absent,
    }
}
