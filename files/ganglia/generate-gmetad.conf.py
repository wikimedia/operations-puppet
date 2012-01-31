#!/usr/bin/python
# Update gmetad.conf file using parameters in stub conf file and generating
# data_source lines for all labs projects as stored in ldap (cn, gidNumber)
# Runs via cron every 8 hours

import filecmp
import ldap
import os
import shutil
import sys
import syslog

# ldap variables
ldapconffile = '/etc/ldap.conf' # ldap conf file to extract bind parameters from
basedn = 'ou=groups,dc=wikimedia,dc=org' # basedn for ldap query
filter = '(&(objectclass=groupofnames)(owner=*))' # filter for ldap query
attrs = ['cn', 'gidNumber'] # attributes to return from ldap query

# gmetad conf variables
gdir = '/etc/ganglia' # ganglia directory
gconf = os.path.join(gdir, 'gmetad.conf') # location of live gmetad conf file
gconfstub = gconf + '.labsstub' # location of gmetad conf stub file
gconfnew= gconf + '.new' # location to stage new gmetad conf file
gconfbk = gconf + '.bk'	# location to back up old gmetad conf file
gserver = 'aggregator1.pmtpa.wmflabs' # hostname of gmetad server 
portprefix = 2 # number to prefix to gidNumber to create unique port number

# gmetad daemon variables
gdaemon = 'gmetad' # name of gmetad daemon (for restarting)
grestart = ('/etc/init.d/' + gdaemon + ' restart && '
            '/usr/bin/pgrep ' + gdaemon) # gmetad restart and verify commands

def _get_projects_gids():
  """Query ldap and return a dictionary of all projects (cn) and their
     corresponding group IDs (gidNumber);
     raise LDAPError on any ldap failures"""
  # get ldap connect parameters (e.g., uri, binddn, bindpw) from conf file
  ldapconf = {}
  for line in open(ldapconffile):
    splitline = line.strip().split()
    ldapconf[splitline[0]] = splitline[1]

  # establish ldap connection
  con = ldap.initialize(ldapconf['uri'])
  con.protocol_version = ldap.VERSION3
  con.start_tls_s()
  con.simple_bind_s(ldapconf['binddn'], ldapconf['bindpw'])

  # ldap search
  res = con.search_s(basedn, ldap.SCOPE_SUBTREE, filter, attrs)
  projectgid = {}
  for (dn, record) in res:
    projectgid[record['cn'][0]] = int(record['gidNumber'][0])
  return projectgid

def gen_gmetad_conf():
  """Generate new gmetad configuration file, using defaults from gconfstub and
     dynamically adding data_source lines for each project (found in ldap),
     e.g., data_source "testlabs" aggregator1.pmtpa.wmflabs:21002"""
  # get dict of project names and group IDs from ldap, or exit on failure
  try:
    pg = _get_projects_gids()
  except ldap.LDAPError, e:
    syslog.syslog(e)
    sys.exit(3)

  # write conf file
  f = open(gconfnew, 'w')
  for line in open(gconfstub):
    f.write(line)
    if line == '# BEGIN AUTOGEN FROM CRON\n':
      for p in sorted(pg):
        # write out data_source line to conf file, e.g.,
        # data_source "testlabs" aggregator1.pmtpa.wmflabs:21002
        f.write('data_source "%s" %s:%d%d\n' % (p, gserver, portprefix, pg[p]))
  f.close()

def cond_restart_gmetad():
  """Restart gmetad if the conf file has changed and verify restart;
     exit with error code 1 or 2, to indicate 1 or 2 restart failures"""
  # update the conf file if it has changed
  if filecmp.cmp(gconf, gconfnew):
    syslog.syslog("INFO: %s config has not changed; no reload needed" % gdaemon)
  else:
    shutil.copyfile(gconf, gconfbk)
    shutil.copyfile(gconfnew, gconf)
    # restart the daemon, verify, and attempt to revert if needed
    if os.system(grestart) == 0:
      syslog.syslog("INFO: %s new config loaded successfully" % gdaemon)
    else:
      shutil.copyfile(gconfbk, gconf)
      # verify revert attempt
      if os.system(grestart) == 0:
        syslog.syslog(("WARN: %s failed to load new config, but "
                       "has been successfully reverted") % gdaemon)
        sys.exit(1)
      else:
        syslog.syslog(("ERROR: %s failed to load new config, and "
                       "revert failed; daemon is not running!") % gdaemon)
        sys.exit(2)


if __name__ == "__main__":
  gen_gmetad_conf()
  cond_restart_gmetad()
