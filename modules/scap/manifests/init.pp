# == Class scap
#
# Common role for scap masters and targets

class scap ($deployment_server = 'deployment') {

    package { 'scap':
        ensure => '3.0.2-1',
    }

    file { '/etc/scap.cfg':
        source => template('scap/scap.cfg.erb'),
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
