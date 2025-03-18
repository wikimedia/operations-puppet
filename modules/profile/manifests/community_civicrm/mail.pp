# SPDX-License-Identifier: Apache-2.0
# @summary the inbound mail server setup for the community_civicrm site

class profile::community_civicrm::mail (
  Stdlib::Fqdn $site_name = lookup('profile::community_civicrm::httpd::site_name', {'default_value' => 'community-crm.wikimedia.org'}),
){

  class { 'profile::postfix::mx':
    config                 => {
      mailbox_command => '/usr/lib/dovecot/dovecot-lda -f "$SENDER" -a "$RECIPIENT"',
      mydestination   => [ $site_name, '$myhostname', 'localhost.$mydomain', 'localhost' ],
    },

    # Set up the generic addresses so they will go somewhere useful.
    # Not 100% sure this is used but will want to check. Couldn't fully test in my cloudvps testing.
    domain_aliases_generic => [ $site_name ],
  }
}
