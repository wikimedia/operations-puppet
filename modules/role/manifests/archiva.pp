# Class: role::archiva
#
# Installs Apache Archiva and sets up a systemd timer to symlink .jar files to a git-fat store.
class role::archiva {
    system::role { 'archiva': description => 'Apache Archiva Host' }

    include profile::base::production
    include profile::base::firewall
    include profile::java
    include profile::nginx
    include profile::archiva
    include profile::archiva::proxy
}

