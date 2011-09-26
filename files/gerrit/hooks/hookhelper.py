#!/usr/bin/python
import sys
import re
import paramiko
import socket
import json
import traceback
from rtkit.resource import RTResource

sys.path.append('/var/lib/gerrit2/review_site/etc')
import hookconfig

class HookHelper:
	def __init__(this):
		this.patchsets = {}

	def ssh_connect(this):
		this.ssh = paramiko.SSHClient()
		this.ssh.load_host_keys('/var/lib/gerrit2/.ssh/known_hosts')
		try:
			this.ssh.connect(hookconfig.sshhost, hookconfig.sshport, hookconfig.gerrituser, key_filename="/var/lib/gerrit2/.ssh/id_rsa")
			return True
		except (paramiko.SSHException, socket.error):
			sys.stderr.write("Failed to connect to %s." % hookconfig.sshhost)
			traceback.print_exc(file=sys.stderr)
			return False

	def ssh_exec_command(this, command):
		try:
			connected = this.ssh_connect()
			if not connected:
				return (None, None, None)
			return this.ssh.exec_command(command)
		except (paramiko.SSHException, socket.error):
			sys.stderr.write("Failed to connect to %s." % hookconfig.sshhost)
			traceback.print_exc(file=sys.stderr)
			return (None, None, None)

	def ssh_close(this):
		this.ssh.close()

	def get_patchsets(this, change):
		command = 'gerrit query --format=JSON --patch-sets ' + change
		stdin, stdout, stderr = this.ssh_exec_command(command)
		if not stdout:
			sys.stderr.write("Couldn't find patchset for change: " + change + "\n")
			return False
		queryresult = stdout.readlines()
		try:
			this.patchsets[change] = json.loads(queryresult[0])
			return True
		except Exception:
			sys.stderr.write("Couldn't load patchset json for change: " + change + "\n")
			traceback.print_exc(file=sys.stderr)
			return False

	def get_subject(this, change):
		if change not in this.patchsets:
			patchsets_fetched = this.get_patchsets(change)
			if not patchsets_fetched:
				return None
		subject = str(this.patchsets[change]['subject'])
		if not subject:
			subject = "(no subject)"
		return subject

	def get_ref(this, change, patchset):
		if change not in this.patchsets:
			patchsets_fetched = this.get_patchsets(change)
			if not patchsets_fetched:
				return None
		ref = str(this.patchsets[change]['patchSets'][patchset - 1]['ref'])
		if hookconfig.debug:
			sys.stderr.write("Ref fetched: " + ref + "\n")
		if not ref:
			sys.stderr.write("Failed to find a ref for this change")
			return None
		return ref

	def get_comments(this, change):
		# Not functional, support isn't in Gerrit yet
		if change not in this.patchsets[change]:
			patchsets_fetched = this.get_patchsets(change)
			if not patchsets_fetched:
				return None

	def set_verify(this, status, commit, message):
		command = 'gerrit approve'
		if status == "pass":
			command = command + ' --verified "' + hookconfig.failscore + '" -m ' + pipes.quote(hookconfig.passmessage)
		else:
			command = command + ' --verified "' + hookconfig.passscore + '" -m ' + pipes.quote(hookconfig.failmessage) + pipes.quote(message)
		command = command + ' ' + commit
		this.ssh_exec_command(command)
		return True

	def log_to_file(this, project, message):
		if hookconfig.logdir and hookconfig.logdir[-1] == '/':
			hookconfig.logdir = hookconfig.logdir[0:-1]
		if project in hookconfig.filenames: 
			filename = hookconfig.logdir + "/" + hookconfig.filenames[project]
		f = open(filename, 'a')
		f.write(message)
		f.close()

	def update_rt(this, change, changeurl):
		messages = []
		messages.append(this.get_subject(change))
		# TODO: add this in when it's possible to get comments from gerrit's query api
		#messages.extend(this.get_comments(change))
		for message in messages:
			match = re.search('resolves?:?\s?RT\s?#?\s?(\d+)', message, re.I)
			if match:
				ticketid = match.group(1)
				resource = RTResource(hookconfig.rtresturl, (hookconfig.gerrituser, hookconfig.gerritpass))
				content = {
					'Status': 'resolved',
					'Resolved': 'Resolved in change ' + change + ' (' + changeurl + ').'
				}
				try:
					resource.post(path="ticket/" + ticketid, payload=content)
				except RTResourceError as e:
					sys.stderr.write("Failed to update RT #" + ticketid + "; error: " + e.response.status)
				break
