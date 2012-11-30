#!/usr/bin/python

import os
import subprocess

def main():
	prefix = os.environ['DEPLOY_ROLLOUT_PREFIX']
	tag = os.environ['DEPLOY_ROLLOUT_TAG']
	#TODO: Use this message to notify IRC
	#msg = os.environ['DEPLOY_DEPLOY_TEXT']

	#TODO: fetch this info from pillars
	repotopdir = '/mnt/deployment'
	if prefix.startswith('slot'):
		repodir = repotopdir + '/common/' + prefix
	elif prefix.startswith('common'):
		repodir = repotopdir + '/common'
	else:
		print 'This repo does not match any configured in the sync hooks. It is new? If not, did you forget to set a prefix? Aborting.'
		return 1
	
	# Ensure the fetch will work for the repo
	p = subprocess.Popen('git update-server-info', cwd=repodir + '/.git/', shell=True, stderr=subprocess.PIPE)
	err = p.communicate()[0]
	if err:
		print err
	# Ensure the fetch will work for the extensions
	if os.path.isdir(repodir + '/extensions'):
		extensiondir = repodir + '/extensions'
		p = subprocess.Popen('git submodule foreach "git tag %s"' % tag, cwd=repodir, shell=True, stderr=subprocess.PIPE)
		out = p.communicate()[0]
		for extension in os.listdir(repodir + '/extensions'):
			p = subprocess.Popen('git update-server-info', cwd=extensiondir + '/' + extension + '/.git/', shell=True, stderr=subprocess.PIPE)
			out = p.communicate()[0]
	print "Running: sudo salt-call publish.runner deploy.fetch '%s'" % (prefix)
	p = subprocess.Popen("sudo salt-call publish.runner deploy.fetch '%s'" % (prefix), shell=True, stdout=subprocess.PIPE)
	out = p.communicate()[0]
	print(out)
	print "Running: sudo salt-call publish.runner deploy.checkout '%s'" % (prefix)
	p = subprocess.Popen("sudo salt-call publish.runner deploy.checkout '%s'" % (prefix), shell=True, stdout=subprocess.PIPE)
	out = p.communicate()[0]
	print(out)

if __name__ == "__main__":
	main()
