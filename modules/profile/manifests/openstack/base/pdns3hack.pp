# why this hack? We detected in the last minute that designate in Mitaka only
# works with pdns v3, which is only in Debian jessie.
# Once we move to Openstack > Mitaka (hopefully soon) this hack shouldn't be
# required. Why you didn't include all this in the serverpackages.pp tree?
# because that is present in every single cloud server, and we only want this hack
# to be present in cloudservices nodes.
class profile::openstack::base::pdns3hack(
) {
    requires_os('debian >= stretch')

    $repo_filename = '/etc/apt/sources.list.d/jessie_pdns3hack.list'
    $repo_options  = '[check-valid-until=no,trusted=yes]'
    $repo_url      = 'http://archive.debian.org/debian-archive/debian/'

    apt::pin { 'pdns3hack':
        package  => 'pdns-server pdns-recursor pdns-backend-mysql',
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
