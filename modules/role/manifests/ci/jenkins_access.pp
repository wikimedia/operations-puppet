# Grants genkins access to instances this is applied on
# Also turns them into a jenkins slave
# Used mostly for *oids atm.
class role::ci::jenkins_access {
    # Allow ssh access from the Jenkins master to the server where citoid is
    # running
    include contint::firewall::labs

    # Instance got to be a Jenkins slave so we can update citoid whenever a
    # change is made on mediawiki/services/citoid repository
    include role::ci::slave::labs::common
    # Also need the slave scripts for multi-git.sh
    include contint::slave_scripts
}

