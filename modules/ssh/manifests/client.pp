class ssh::client {
    package { "openssh-client":
        ensure => latest
    }
}
