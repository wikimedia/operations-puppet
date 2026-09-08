# @summary Includes the rspamd.com/apt-stable APT repository
# This replicates the instructions on the rspamd site:
# https://rspamd.com/downloads.html
#
# @see rspamd::repo
# 
# @api private
class rspamd::repo::apt_stable {
  assert_private()
  include rspamd
  include apt

  # Here we have tried to replicate the instructions on the rspamd site:
  #
  # https://rspamd.com/downloads.html
  #
  $default_baseurl = 'http://rspamd.com/apt-stable/'

  $_baseurl = pick($rspamd::repo_baseurl, $default_baseurl)

  apt::pin { 'rspamd_stable':
    originator => 'rspamd.com',
    priority   => 500,
  }
  -> apt::source { 'rspamd_stable':
    location => $_baseurl,
    release  => $facts['os']['distro']['codename'],
    repos    => 'main',
    key      => {
      id     => '3FA347D5E599BE4595CA2576FFA232EDBF21E25E',
      source => 'https://rspamd.com/apt-stable/gpg.key',
    },
  }

  Apt::Source['rspamd_stable'] -> Package<|tag == 'rspamd'|>
  Class['Apt::Update'] -> Package<|tag == 'rspamd'|>
}
