# SPDX-License-Identifier: Apache-2.0
# https://community-crm.wikimedia.org
#
# Community civicrm instance
#
# maintainer: fr-tech
# phabricator-tag: Fundraising-Backlog
class profile::community_civicrm (
    String $config_nonce = lookup('profile::community_civicrm::config_nonce'),
    String $db_pass = lookup('profile::community_civicrm::dbpassword'),
    String $hash_salt = lookup('profile::community_civicrm::hash_salt'),
){

    motd::script { 'deployment_info':
        ensure   => present,
        priority => 99,
        content  => template('community_civicrm/deployment_info.motd.erb'),
    }

    include profile::community_civicrm::db
    include profile::community_civicrm::httpd

    class { 'community_civicrm':
        config_nonce => $config_nonce,
        db_pass      => $db_pass,
        hash_salt    => $hash_salt,
        site_name    => $profile::community_civicrm::httpd::site_name,
    }

}
