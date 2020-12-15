class puppetmaster::generators(
    Wmflib::Ensure $ensure = 'present'
){

    # python-mysqldb is used as one of python-sqlalchemy backends
    ensure_packages(['python3-requests', 'python-mysqldb', 'python-sqlalchemy', 'python-yaml'])

    file {'/usr/local/bin/naggen2':
        ensure  => $ensure,
        owner   => 'root',
        group   => 'root',
        mode    => '0555',
        source  => 'puppet:///modules/puppetmaster/naggen2.py',
        require => Package['python3-requests'],
    }
}
