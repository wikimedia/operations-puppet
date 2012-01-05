#!/usr/bin/python
import sys
import os
import shutil
import subprocess
import re
from hookhelper import HookHelper
from optparse import OptionParser

sys.path.append('/var/lib/gerrit2/review_site/etc')
import hookconfig

class PuppetHooks:
	def changeAbandoned(this, helper, options):
		pass
	
	def changeMerged(this, helper, options):
		# Resolve any RT tickets that this change mentions as resolveds
		helper.update_rt(options.change, options.changeurl)
	
	def changeRestored(this, helper, options):
		pass
	
	def commentAdded(this, helper, options):
		pass
	
	def patchsetCreated(this, helper, options):
		if not hookconfig.tmpdir:
			sys.stderr.write("tmpdir isn't set in the configuration, not running lint tests.")
			# Not having tmpdir is dangerous!
			return
		if options.project == "operations/private":
			# TODO: make this configurable
			return
		ref = helper.get_ref(options.change, options.patchset)
		if not ref:
			return
		if hookconfig.tmpdir[-1] == '/':
			hookconfig.tmpdir = hookconfig.tmpdir[0:-1]
		directory = hookconfig.tmpdir + '/' +	options.change
		repo = 'ssh://' + hookconfig.gerrituser + '@' + hookconfig.sshhost + ':' + str(hookconfig.sshport) + '/' + options.project
		command = '/usr/bin/git init ' + directory
		if hookconfig.debug:
			sys.stderr.write("Running the following git command: " + command + "\n")
		proc = subprocess.Popen(command, stdout=subprocess.PIPE, stderr=subprocess.PIPE, shell=True, env={"GIT_DIR": directory + '/.git'})
		(stdoutdata, stferrdata) = proc.communicate()
		if hookconfig.debug:
			sys.stderr.write("git init stdout: " + stdoutdata + "\n")
			sys.stderr.write("git init stderr: " + stdoutdata + "\n")
		command = '/usr/bin/git pull ' + repo + ' ' + ref
		if hookconfig.debug:
			sys.stderr.write("Running the following git command: " + command + "\n")
		proc = subprocess.Popen(command, shell=True, cwd=directory, env={"GIT_DIR": directory + '/.git'})
		proc.wait()
		proc = subprocess.Popen('/bin/sed -i \'s%import \"../private%#import \"../private%\' ' + 'manifests/base.pp', shell=True, cwd=directory)
		proc.wait()
		proc = subprocess.Popen('/usr/bin/puppet parser validate ' + 'manifests/site.pp', shell=True, stdout=subprocess.PIPE, cwd=directory)
		(stdoutdata, stderrdata) = proc.communicate()
		shutil.rmtree(directory)
		procstatus = proc.returncode
		if procstatus == 0:
			status = "pass"
		else:
			status = "fail"
		message = ""
		if stdoutdata:
			message = stdoutdata
		if stderrdata:
			message = message + stderrdata
		verifyset = helper.set_verify(status, options.commit, message)
		if not verifyset:
			sys.stderr.write("Failed to set verify score")
