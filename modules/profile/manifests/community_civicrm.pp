# SPDX-License-Identifier: Apache-2.0
# https://community-crm.wikimedia.org
#
# Community civicrm instance
#
# maintainer: fr-tech
# phabricator-tag: Fundraising-Backlog
#
# @param config_nonce a unique value to use in the site configuration dir
# @param db_pass password for civicrm admin db user
# @param git_branch branch to check out of git for civicrm code
# @param hash_salt salt for one-time login links, cancel links, form tokens, etc.

class profile::community_civicrm (
    String $config_nonce = lookup('profile::community_civicrm::config_nonce'),
    String $db_pass = lookup('profile::community_civicrm::dbpassword'),
    String $git_branch = lookup('profile::community_civicrm::git_branch', {'default_value' => 'main'}),
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
        git_branch   => $git_branch,
        site_name    => $profile::community_civicrm::httpd::site_name,
    }

}
