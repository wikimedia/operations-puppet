class base::preflight {
    exec { 'check 127.0.1.1 in /etc/hosts':
        command => 'grep -q 127.0.1.1 /etc/hosts',
        returns => 1,
    }
}
