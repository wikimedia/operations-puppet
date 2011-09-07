import sys, traceback, ldapsupportlib, pwd, subprocess, os
from optparse import OptionParser

try:   
	import ldap
except ImportError:
	sys.stderr.write("Unable to import LDAP library.\n")
	sys.exit(1)

def main():
	parser = OptionParser(conflict_handler="resolve")
	parser.set_usage("puppetsigner [options]")
	ldapSupportLib = ldapsupportlib.LDAPSupportLib()
	ldapSupportLib.addParserOptions(parser)
	(options, args) = parser.parse_args()
	ldapSupportLib.setBindInfoByOptions(options, parser)
	ds = ldapSupportLib.connect()
	try:
		proc = subprocess.Popen('/usr/sbin/puppetca -l', shell=True, stdout=subprocess.PIPE)
		hosts = proc.communicate()
		hosts = hosts[0].split()
		for host in hosts:
			basedn = getPuppetInfo('ldapbase')
			query = "(&(objectclass=puppetclient)(|(dc=" + host + ")(cnamerecord=" + host + ")(associateddomain=" + host + ")))"
			PosixData = ds.search_s(basedn, ldap.SCOPE_SUBTREE, query)
			if not PosixData:
				path = getPuppetInfo('ssldir') + '/ca/requests/' + host + '.pem'
				try:
					os.remove(path)
				except Exception:
					sys.stderr.write('Failed to remove the certificate: ' + path + '\n')
			else:
				subprocess.Popen(['/usr/sbin/puppetca -s ' + host], shell=True, stderr=subprocess.PIPE)
	except ldap.PROTOCOL_ERROR:
		sys.stderr.write("There was an LDAP protocol error; see traceback.\n")
		traceback.print_exc(file=sys.stderr)
		ds.unbind()
		sys.exit(1)
	except Exception:
		try:
			sys.stderr.write("There was a general error, this is unexpected; see traceback.\n")
			traceback.print_exc(file=sys.stderr)
			ds.unbind()
		except Exception:
			sys.stderr.write("Also failed to unbind.\n")
			traceback.print_exc(file=sys.stderr)
		sys.exit(1)

	ds.unbind()
	sys.exit(0)

def getPuppetInfo(attr, conffile="/etc/puppet/puppet.conf"):
	f = open(conffile)
	for line in f:
		if line.split('=', 1)[0].strip() == attr:
			return line.split('=', 1)[1].strip()
			break

if __name__ == "__main__":
	main()
