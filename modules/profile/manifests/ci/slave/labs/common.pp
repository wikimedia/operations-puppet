# SPDX-License-Identifier: Apache-2.0
# Common configuration to be applied on any labs Jenkins slave
#
class profile::ci::slave::labs::common (
    Boolean $manage_srv = lookup('profile::ci::slave::labs::common::manage_srv')
) {

    # The slaves on labs use the `jenkins-deploy` user which is already
    # configured in labs LDAP.  Thus, we only need to install the dependencies
    # needed by the slave agent, eg the java jre.
    include profile::java

    # Anything that needs publishing to doc.wikimedia.org relies on rsync to
    # fetch files from the agents.
    ensure_packages('rsync')

    if $manage_srv {
        # Need the labs instance extended disk space. T277078.
        include profile::wmcs::lvm
        include profile::labs::lvm::srv
        $require_srv = Mount['/srv']
    } else {
        $require_srv = undef
    }

    # base directory
    file {
        default:
            ensure => directory,
            owner  => 'jenkins-deploy',
            group  => 'wikidev',
            mode   => '0775';
        ['/srv/home']:
            owner   => 'root',
            group   => 'root',
            mode    => '0755',
            require => $require_srv;
        ['/srv/jenkins']:
            require => $require_srv;
        ['/srv/jenkins/cache', '/srv/jenkins/workspace', '/srv/home/jenkins-deploy']: ;
    }

    git::userconfig { '.gitconfig for jenkins-deploy user':
        homedir  => '/srv/home/jenkins-deploy',
        settings => {
            'user' => {
                'name'  => 'Wikimedia Jenkins Deploy',
                'email' => "jenkins-deploy@${::fqdn}",
            },
        },
        require  => File['/srv/home/jenkins-deploy'],
    }
}
