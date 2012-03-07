#!/usr/bin/python
import os
import sys
import re
import paramiko
import socket
import json
import pipes
import traceback
import cookielib
import urllib
import urllib2

sys.path.append('/var/lib/gerrit2/review_site/etc')
import hookconfig

class HookHelper:
	def __init__(self):
		self.patchsets = {}

	def ssh_exec_command(self, command):
		ssh = paramiko.SSHClient()
		ssh.load_host_keys('/var/lib/gerrit2/.ssh/known_hosts')
		try:
			ssh.connect(hookconfig.sshhost, hookconfig.sshport, hookconfig.gerrituser, key_filename="/var/lib/gerrit2/.ssh/id_rsa")
			stdin, stdout, stderr = ssh.exec_command(command)
			out = stdout.readlines()
			err = stderr.readlines()
			ssh.close()
			return (out,err)
		except (paramiko.SSHException, socket.error):
			sys.stderr.write("Failed to connect to %s." % hookconfig.sshhost)
			traceback.print_exc(file=sys.stderr)
			return (None, None)

	def get_patchsets(self, change):
		command = 'gerrit query --format=JSON --patch-sets ' + change
		queryresult, err = self.ssh_exec_command(command)
		if not queryresult:
			sys.stderr.write("Couldn't find patchset for change: " + change + "\n") 
			return False
		try:
			self.patchsets[change] = json.loads(queryresult[0])
			return True
		except Exception:
			sys.stderr.write("Couldn't load patchset json for change: " + change + "\n")
			traceback.print_exc(file=sys.stderr)
			return False

	def get_subject(self, change):
		if change not in self.patchsets:
			patchsets_fetched = self.get_patchsets(change)
			if not patchsets_fetched:
				return None
		subject = str(self.patchsets[change]['subject'])
		if not subject:
			subject = "(no subject)"
		return subject

	def get_ref(self, change, patchset):
		if change not in self.patchsets:
			patchsets_fetched = self.get_patchsets(change)
			if not patchsets_fetched:
				return None
		ref = str(self.patchsets[change]['patchSets'][patchset - 1]['ref'])
		if hookconfig.debug:
			sys.stderr.write("Ref fetched: " + ref + "\n")
		if not ref:
			sys.stderr.write("Failed to find a ref for self change")
			return None
		return ref

	def get_comments(self, change):
		# Not functional, support isn't in Gerrit yet
		if change not in self.patchsets[change]:
			patchsets_fetched = self.get_patchsets(change)
			if not patchsets_fetched:
				return None

	def set_verify(self, status, commit, message):
		command = 'gerrit approve'
		if status == "pass":
			command = command + ' --verified "' + hookconfig.passscore + '" -m ' + pipes.quote(hookconfig.passmessage)
		else:
			command = command + ' --verified "' + hookconfig.failscore + '" -m ' + pipes.quote(hookconfig.failmessage) + pipes.quote(message)
		command = command + ' ' + commit
		self.ssh_exec_command(command)
		return True

	def log_to_file(self, project, branch, message):
		if hookconfig.logdir and hookconfig.logdir[-1] == '/':
			hookconfig.logdir = hookconfig.logdir[0:-1]
		if project in hookconfig.filenames:
			if branch in hookconfig.filenames[project]:
				filename = hookconfig.logdir + "/" + hookconfig.filenames[project][branch]
			else:
				filename = hookconfig.logdir + "/" + hookconfig.filenames[project]["default"]
		else:
			filename = hookconfig.logdir + "/" + hookconfig.filenames["default"]
		f = open(filename, 'a')
		f.write(message)
		f.close()

	def update_rt(self, change, changeurl):
		messages = []
		messages.append(self.get_subject(change))
		# TODO: add self in when it's possible to get comments from gerrit's query api
		#messages.extend(self.get_comments(change))
		ticketid = None
		for message in messages:
			match = re.search('resolves?:?\s?RT\s?#?\s?(\d+)', message, re.I)
			if match:
				ticketid = match.group(1)
		if ticketid:
			COOKIEFILE = os.path.expanduser('~/.rt_cookies.txt')
			cj = cookielib.LWPCookieJar(COOKIEFILE)
			opener = urllib2.build_opener(urllib2.HTTPCookieProcessor(cj))
			urllib2.install_opener(opener)
			try:
				cj.load(ignore_discard=True, ignore_expires=True)
			except IOError:
				pass
			data = {'user': hookconfig.gerrituser, 'pass': hookconfig.gerritpass}
			data = urllib.urlencode(data)
			try:
				opener.open(hookconfig.rtresturl, data)
				cj.save(COOKIEFILE, ignore_discard=True, ignore_expires=True)
				uri = hookconfig.rtresturl + 'ticket/' + ticketid + '/comment'
				message = 'Resolved in change ' + change + ' (' + changeurl + ').'
				data = {'content': 'id: ' + ticketid + '\nAction: comment\nText: ' + message}
				data = urllib.urlencode(data)
				opener.open(uri, data)
				uri = hookconfig.rtresturl + 'ticket/edit'
				data = {'content': 'id: ' + ticketid + '\nStatus: resolved'}
				data = urllib.urlencode(data)
				opener.open(uri, data)
			except urllib2.URLError:
				sys.stderr.write("Failed to update RT")
				traceback.print_exc(file=sys.stderr)
