#!/usr/bin/python
# Update ganglia config files for the ganglia aggregator in labs:
# add gmetad data_source, gmond udp_recv_channel, and gmond tcp_accept_channel
# lines for each labs project, as stored in ldap (cn, gidNumber).
# Runs via cron.

import filecmp
import ldap
import os
import shutil
import sys
import syslog

# ldap variables
ldapconffile = '/etc/ldap.conf' # ldap conf file to extract bind parameters from
basedn = 'ou=groups,dc=wikimedia,dc=org' # basedn for ldap query
lfilter = '(objectclass=groupofnames)' # filter for ldap query
attrs = ['cn', 'gidNumber'] # attributes to return from ldap query

# gmetad and gmond shared variables
gdir = '/etc/ganglia' # ganglia directory
portprefix = 2 # number to prefix to gidNumber to create unique port number

# gmetad variables
gmetadconf = os.path.join(gdir, 'gmetad.conf') # live gmetad conf file
gmetadconfstub = gmetadconf + '.labsstub' # gmetad conf stub file
gmetadconfnew = gmetadconf + '.new' # location to stage new gmetad conf file
gserver = 'aggregator1.pmtpa.wmflabs' # hostname of the aggregator server
gmetadaemon = 'gmetad' # name of gmetad daemon (for restarting)
gmetadps = 'gmetad' # name of gmetad ps (for verifying restart)

# gmond variables
gmondconfstub = os.path.join(gdir, 'gmond.conf.labsstub')
gmondaemon = 'ganglia-monitor' # name of gmond daemon (for restarting)
gmondps = 'gmond' # name of gmond daemon (for verifying restart)

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
  res = con.search_s(basedn, ldap.SCOPE_SUBTREE, lfilter, attrs)
  projectgid = {}
  for (dn, record) in res:
    projectgid[record['cn'][0]] = int(record['gidNumber'][0])
  return projectgid

def gen_ganglia_conf():
  """Generate new ganglia config files, using defaults from gconfstub and
     dynamically adding data_source lines for each project (found in ldap),
     e.g., data_source "testlabs" aggregator1.pmtpa.wmflabs:21002"""
  # get dict of project names and group IDs from ldap, or exit on failure
  try:
    pg = _get_projects_gids()
  except ldap.LDAPError, e:
    syslog.syslog(e)
    sys.exit(3)

  # write new gmetad conf file
  f = open(gmetadconfnew, 'w')
  for line in open(gmetadconfstub):
    f.write(line)
    if line == '# BEGIN AUTOGEN FROM CRON\n':
      for p in sorted(pg):
        if p[:8] != 'project-':
          continue
        # write out data_source line to conf file, e.g.,
        # data_source "testlabs" aggregator1.pmtpa.wmflabs:21002
        f.write('data_source "%s" %s:%d%d\n' % (p[8:], gserver, portprefix, pg[p]))
  f.close()

  # write new gmond conf files
  for p in sorted(pg):
    if p[:8] != 'project-':
      continue
    g = open(os.path.join(gdir, 'gmond-%s.conf.new' % p[8:]), 'w')
    for line in open(gmondconfstub):
      g.write(line)
      if line == '# BEGIN AUTOGEN FROM CRON\n':
        # set cluster so hosts show up grouped by project name
        g.write('cluster {\n  name = "%s"\n}\n' % p[8:])
        # write out udp_recv_channel and tcp_accept_channel stanzas
        g.write('udp_recv_channel {\n  port = %d%s\n}\n' % (portprefix, pg[p]))
        g.write('tcp_accept_channel {\n  port = %d%s\n}\n\n' % (portprefix, pg[p]))
    g.close()

def cond_restart(confs, daemon, ps):
  """Restart daemon if any new conf files have changed and verify restart;
     exit with error code 1 or 2, to indicate 1 or 2 restart failures"""
  restart = ('/etc/init.d/' + daemon + ' restart && '
             '/usr/bin/pgrep ' + ps) # restart/verify commands
  diffcount = 0
  for conf in confs:
    confnew = conf + '.new' # location of new conf file
    confbk = conf + '.bk' # location to backup old conf file
    # update the conf file if it has changed
    if not (os.path.isfile(conf) and filecmp.cmp(conf, confnew)):
      diffcount += 1
      if os.path.isfile(conf):
        shutil.copyfile(conf, confbk)
      shutil.copyfile(confnew, conf)
  if diffcount == 0:
      syslog.syslog("INFO: %s config has not changed; no reload needed" % daemon)
  else:
    # restart the daemon and verify
    if os.system(restart) == 0:
      syslog.syslog("INFO: %s new config loaded successfully" % daemon)
    # attempt to revert if needed
    else:
      for conf in confs:
        confbk = conf + '.bk' # location of backup conf file
        if os.path.isfile(confbk):
          shutil.copyfile(confbk, conf)
      # verify revert attempt
      if os.system(restart) == 0:
        syslog.syslog(("WARN: %s failed to load new config, but "
                       "has been successfully reverted") % daemon)
        sys.exit(1)
      else:
        syslog.syslog(("ERROR: %s failed to load new config, and "
                       "revert failed; daemon is not running!") % daemon)
        sys.exit(2)


if __name__ == "__main__":
  gen_ganglia_conf()
  # diff new gmetad conf file and restart if needed
  cond_restart([gmetadconf], gmetadaemon, gmetadps)
  # diff new gmond conf files (gmond-*.conf.new) and restart if needed
  gmondconfs = [os.path.join(gdir, f[:-4])
                for f in os.listdir(gdir) 
                if f[:6] == 'gmond-' and f[-9:] == '.conf.new']
  cond_restart(gmondconfs, gmondaemon, gmondps)
