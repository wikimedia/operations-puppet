# Why this hack? When installing OpenStack Mitaka on Stretch, we detected in
# the last minute that designate in Mitaka only works with pdns v3, which is
# only in Debian jessie.
# Now that we've moved to Openstack Newton on the cloudservices boxes this hack
# shouldn't be required. However, Designate uses different drivers for pdns
# v4, so switching over will require some work.
class profile::openstack::base::pdns3hack(
) {
    requires_os('debian >= stretch')

    $repo_filename = '/etc/apt/sources.list.d/jessie_pdns3hack.list'
    $repo_options  = '[check-valid-until=no,trusted=yes]'
    $repo_url      = 'http://archive.debian.org/debian-archive/debian/'

    apt::pin { 'pdns3hack':
        package  => 'pdns-server pdns-backend-mysql',
        pin      => 'release n=jessie',
        priority => '1001',
        before   => File[$repo_filename],
    }

    file { $repo_filename:
        ensure  => 'present',
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        content => "deb ${repo_options} ${repo_url} jessie main",
        notify  => Exec['pdns3hack_apt_upgrade'],
    }

    exec { 'pdns3hack_apt_upgrade':
        command     => '/usr/bin/apt-get update',
        require     => File[$repo_filename],
        subscribe   => File[$repo_filename],
        refreshonly => true,
        logoutput   => true,
    }
    # the repo should be setup before we try to install the server
    Exec['pdns3hack_apt_upgrade'] -> Package[pdns-server]
    Exec['pdns3hack_apt_upgrade'] -> Package[pdns-recursor]
    Exec['pdns3hack_apt_upgrade'] -> Package[pdns-backend-mysql]
}
