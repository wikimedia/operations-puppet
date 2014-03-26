class admin::groups::misc {

    #assigned almost universally as primary user group
    @admin::group { 'wikidev':
               gid => 500,
    }

    @admin::group { 'jenkins':
        gid        => 505,
        sudo_privs => [
                          'ALL = (jenkins) NOPASSWD: ALL',
                          'ALL = (jenkins-slave) NOPASSWD: ALL',
                          'ALL = (gerritslave) NOPASSWD: ALL',
                          'ALL = NOPASSWD: /etc/init.d/jenkins',
                          'ALL = (testswarm) NOPASSWD: ALL',
                          'ALL = NOPASSWD: /etc/init.d/postgresql-8.4',
                          'ALL = (postgres) NOPASSWD: /usr/bin/psql'
                      ],
        members    => ['demon', 'krinkle', 'reedy', 'dsc', 'mholmquist']
    }
}
