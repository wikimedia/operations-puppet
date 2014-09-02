# preflight checks are meant to make sure a given host can safely run puppet,
# possibly for the first time (i.e. right after provisioning)

class base::preflight {
    exec { 'check 127.0.1.1 in /etc/hosts':
        command => 'grep -q 127.0.1.1 /etc/hosts',
        returns => 1,
    }
}
