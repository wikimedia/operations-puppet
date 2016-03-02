# == Class scap
#
# Common role for scap masters and targets

class scap {

    package { 'scap':
        ensure => '3.0.3-1',
    }

    file { '/etc/scap.cfg':
        source => 'puppet:///modules/scap/scap.cfg',
        owner  => 'root',
        group  => 'root',
        mode   => '0444',
    }

    require_package([
        'python-psutil',
        'python-netifaces',
        'python-yaml',
        'python-requests',
        'python-jinja2',
    ])
}
