# == Class scap
#
# Common role for scap masters and targets

class scap {
    # Using trebuchet provider while scap service deployment is under
    # development—chicken and egg things
    #
    # This should be removed once scap3 is in a final state (i.e. packaged
    # or deployed via another method)
    package { 'scap':
        ensure   => latest,
        provider => 'trebuchet',
    }

    file { '/etc/scap.cfg':
        source  => 'puppet:///modules/scap/scap.cfg',
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
    }

    require_package([
        'python-psutil',
        'python-netifaces',
        'python-yaml',
        'python-requests',
        'python-jinja2',
    ])
}
