class ssh {
    include ssh::client,
        ssh::hostkeys::publish,
        ssh::config,
        ssh::daemon

    class { "ssh::hostkeys::collect": }
}

class ssh::client {
    package { "openssh-client":
        ensure => latest
    }
}

define sshhostkey($ip, $key) {
    $host = regsubst($title, '^([^\.]+)\..*$', '\1')

    sshkey {
        "$title":
            type => ssh-rsa,
            key => $key,
            ensure => present;
        "$host":
            type => ssh-rsa,
            key => $key,
            ensure => present;
        "$ip":
            type => ssh-rsa,
            key => $key,
            ensure => present;
   }
}


class ssh::hostkeys::publish {
    include ssh::client

    # Store this hosts's host key
    case $sshrsakey {
        "": {
            err("No sshrsakey on $fqdn")
        }
        default: {
            debug("Storing RSA ssh hostkey for $hostname.$domain")
            @@sshhostkey { $fqdn: ip => $ipaddress, key => $sshrsakey }
        }
    }
}

class ssh::hostkeys::collect {
    # Do this about twice a day
    $potm = inline_template('<%= srand ; (rand(25) == 5).to_s.capitalize -%>')
    if $hostname == "fenari" or $hostname == "tin" or $hostname == "bast1001" or $potm == "True" {
        notice("Collecting SSH host keys on $hostname.")

        # Install all collected ssh host keys
        Sshhostkey <<| |>>

        file { '/etc/ssh/ssh_known_hosts':
            ensure => present,
            owner  => root,
            group  => root,
            mode   => '0644',
        }
    }
}


class ssh::bastion {
    $ssh_banner = '/etc/ssh/sshd_banner'
    if ( $realm == "labs" ) {
        @file { $ssh_banner:
            owner   => root,
            group   => root,
            mode    => '0444',
            tag     => 'ssh_banner',
            content => "
If you are having access problems, please see: https://wikitech.wikimedia.org/wiki/Access#Accessing_public_and_private_instances
"
        }
    }

    package { 'mosh':
        ensure => present
    }
}

class ssh::config {
    if ( $realm == "labs" ) {
        if versioncmp($::lsbdistrelease, "12.04") >= 0 {
            $ssh_authorized_keys_file = "/etc/ssh/userkeys/%u/.ssh/authorized_keys /public/keys/%u/.ssh/authorized_keys"
        } else {
            $ssh_authorized_keys_file = "/etc/ssh/userkeys/%u/.ssh/authorized_keys"
            $ssh_authorized_keys_file2 = "/public/keys/%u/.ssh/authorized_keys"
        }
    }

    $ssh_banner = $ssh::bastion::ssh_banner

    File <| tag == 'ssh_banner' |>

    file { "/etc/ssh/sshd_config":
        owner => root,
        group => root,
        mode  => '0444',
        content => template("ssh/sshd_config.erb");
    }
}

class ssh::daemon {
    package { "openssh-server":
        ensure => latest;
    }

    service {
        ssh:
            ensure    => running,
            subscribe => File["/etc/ssh/sshd_config"];
    }
}
