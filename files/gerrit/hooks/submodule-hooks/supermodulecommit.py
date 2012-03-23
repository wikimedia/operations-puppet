 
import xmlrpclib
import sys
import ConfigParser
import commands
import re
import getopt
import os.path
import array
from git import Git
from log import getLogger


class SupermoduleCommit():

	def __init__(self, configProfile):
		self.config = configProfile
		self.log = getLogger("Main")
		self.log.debug("Config projects: " + str(self.config.projects))

	def checkoutTrackingBranch(self, git, branch):
		if git.branchExists(branch):
			git.checkout(branch, True)
		else:
			git.createBranch(branch, "origin/"+branch)
			git.checkout(branch, True)

	def addSuperModuleCommit(self, id, hash, url, who, branch, project):	
		self.log.debug("branch: " + branch + ", project:" + project)
		
		hasSuperModule = False
		isSuperModuleBr = False
		self.log.debug("Project names: " + str(self.config.projects))
		
		projectNames = self.config.projects.keys()
		for proj in projectNames:
				self.log.debug("project: " + project + " proj: " + proj)
				if project.lower() == proj:
					hasSuperModule = True
					break
	
		for br in self.config.branches:
			if branch == br:
				isSuperModuleBr = True
				break

		self.log.debug("isSuperModuleBr: " + str(isSuperModuleBr) + " hasSuperModule: " + str(hasSuperModule))	
		if isSuperModuleBr and hasSuperModule:
			self.log.debug("Git Profile Path: " + str(self.config.profile))
			git = Git(self.config.profile)
			self.checkoutTrackingBranch(git, branch)
			git.pull()
			git.submodule("update","--init")
			gitSubmoduleProfile = {'git':self.config.superRepoPath + self.config.projects[project.lower()]}
			gitSubmodule = Git(gitSubmoduleProfile)
			self.log.debug("checking out hash: " + hash)
			gitSubmodule.fetch()
	
			if self.isOptOut(gitSubmodule, hash):
				return	
	
			gitSubmodule.checkout(hash, True)
			git.add(".")
			commitMsg = "Auto checkin: " + self.getCommitMessage(gitSubmodule, hash) + "\nuser:" + who + "\nhash:" + hash + "\nproject: " + project
			self.log.debug("commiting in super module: " +  commitMsg)
			git.commit(commitMsg)
			self.log.debug("pushing super module to branch: " + branch)
			git.push(branch)
		else:
			self.log.debug("No super module commit is required.")
		
	def isOptOut(self, git, hash):
		message = self.getCommitMessage(git, hash).lower()
		self.log.debug("Commit message: " + message)
		m = re.search('Update-Superproject:\s*false', message, flags=re.IGNORECASE)
		
		return m is not None
	
	def getCommitMessage(self, git, hash):
		commitObj = git.getCommit(hash)
		message = commitObj.comment
		return str(message)	

class ConfigProfile():
	def __init__(self, user, email, superRepoPath, profile, projects, branches, smtp_host, sendmailto):
		self.user = user
		self.email = email
		self.superRepoPath = superRepoPath
		self.profile = profile
		self.projects = projects
		self.branches = branches
		self.smtp_host = smtp_host
		self.sendmailto = sendmailto
