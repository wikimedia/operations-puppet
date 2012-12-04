#!/usr/bin/python

import os
import subprocess
import json

def main():
	print "Running: sudo salt-call --json-out pillar.data"
	p = subprocess.Popen("sudo salt-call --json-out pillar.data", shell=True, stdout=subprocess.PIPE)
	out = p.communicate()[0]
	try:
		pillar = json.loads(out)
	except ValueError:
		print "JSON data wasn't loaded from the pillar call. git-deploy can't configure itself. Exiting."
		return 1
	try:
		pillar = pillar['local']
	except KeyError:
		print "Couldn't find 'local' in json output from pillar data. git-deploy can't configure itself. Exiting."
		return 1
	
	prefix = os.environ['DEPLOY_ROLLOUT_PREFIX']
	tag = os.environ['DEPLOY_ROLLOUT_TAG']
	#TODO: Use this message to notify IRC
	#msg = os.environ['DEPLOY_DEPLOY_TEXT']

	try:
		repodir = pillar['repo_locations'][prefix]
	except KeyError:
		print "This repo isn't configured. Have you added it in puppet? Exiting."
		return 1
	
	# Ensure the fetch will work for the repo
	p = subprocess.Popen('git update-server-info', cwd=repodir + '/.git/', shell=True, stderr=subprocess.PIPE)
	err = p.communicate()[0]
	if err:
		print err
	# Ensure the fetch will work for the extensions
	#TODO: make this generic for submodules - it doesn't need to be specific to extensions
	if os.path.isdir(repodir + '/extensions'):
		extensiondir = repodir + '/extensions'
		p = subprocess.Popen('git submodule foreach "git tag %s"' % tag, cwd=repodir, shell=True, stderr=subprocess.PIPE)
		out = p.communicate()[0]
		for extension in os.listdir(repodir + '/.git/modules/extensions'):
			p = subprocess.Popen('git update-server-info', cwd=extensiondir + '/' + extension, shell=True, stderr=subprocess.PIPE)
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
