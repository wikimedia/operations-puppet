# @summary Includes the rspamd.com/rpm-stable RPM repository
#
# This replicates the instructions on the rspamd site:
# https://rspamd.com/downloads.html
#
# @see rspamd::repo
# 
# @api private
class rspamd::repo::rpm_stable {
  assert_private()
  include rspamd
  require epel

  if ($facts['os']['name'] == 'Fedora') {
    $_osname = downcase($facts['os']['name'])
  } else {
    $_osname = 'centos'
  }
  $default_baseurl = "http://rspamd.com/rpm-stable/${_osname}-${facts['os']['release']['major']}/${facts['os']['hardware']}/"

  $_baseurl = pick($rspamd::repo_baseurl, $default_baseurl)

  yumrepo { 'rspamd':
    baseurl       => $_baseurl,
    descr         => 'Rspamd stable repository',
    enabled       => '1',
    gpgcheck      => '1',
    gpgkey        => 'http://rspamd.com/rpm/gpg.key',
    repo_gpgcheck => '1',
  }

  Yumrepo['rspamd'] -> Package<|tag == 'rspamd'|>
}
