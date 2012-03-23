#!/usr/bin/python2
#
# Refer to the XML-RPC Javadoc to see what calls are available:
# http://docs.atlassian.com/software/jira/docs/api/rpc-jira-plugin/latest/com/atlassian/jira/rpc/xmlrpc/XmlRpcService.html
 
import xmlrpclib
import sys
import traceback
import ConfigParser
import commands
import re
import getopt
import os.path
import array
import smtplib
from git import Git
from log import getLogger
from supermodulecommit import ConfigProfile
from supermodulecommit import SupermoduleCommit

log = getLogger("Main")

def readConfig():
    # May need to modify this path to be fully qualified (ie. /srv/gerrit/cfg/hooks/submodulehook.config)
	config_path = os.path.expanduser('./submodulehook.config')
	configParser = ConfigParser.RawConfigParser()
	config = configParser.read(config_path)
	config = configParser._sections
	
	log.debug("Config: " + str(config))	
	core = config['core']
	user = core.get('user')
	email = core.get('email')
	superRepoPath = core.get('superrepopath')
	smtp_host = core.get('smtphost')
	sendmailto = core.get('sendmailto')
	log.debug("smtp_host: " + smtp_host + " sendmailto: " + sendmailto)
	
	#Strip additional whitespace off of branches
	branchesStr = core.get('branches')
	branches = [x.strip() for x in branchesStr.split(',')]

	projects = config['projects']
	log.debug("Projects Config: " + str(projects))
	profile = {'git': superRepoPath}
	log.debug("Profile path: " + str(profile))

	return ConfigProfile(user, email, superRepoPath, profile, projects, branches, smtp_host, sendmailto)

def sendEmail(to,subject,content, smpt_host):
    sender = 'gerrit-hook@gerrit'
    print("Sending email to ", to)
    headers = "From: %s\r\nTo: %s\r\nSubject: %s\r\n\r\n" % (sender, to, subject)
    message = headers + content
    server = smtplib.SMTP(smpt_host)
    server.sendmail(sender, to, message)
    server.quit()
    return True

def main():

    need = ['change=', 'change-url=', 'commit=', 'project=', 'branch=', 'uploader=',
            'patchset=', 'abandoner=', 'reason=', 'submitter=']
    optlist, args = getopt.getopt(sys.argv[1:], '', need)
    id = url = hash = who = branch = project = ''

    log.debug("Entering change-merged hook ------------")
    log.debug("arg length:"+str(len(optlist)))
    for o, a in optlist:
	log.debug("o:"+o+",a:"+a)
        if o == '--change': id = a
        elif o == '--change-url': url = a
        elif o == '--commit': hash = a
        elif o == '--uploader': who = a
        elif o == '--submitter': who = a
        elif o == '--abandoner': who = a
        elif o == '--branch': branch = a
	elif o == '--project': project = a

    try:    
        config = readConfig()

        supermodule = SupermoduleCommit(config)
        supermodule.addSuperModuleCommit(id, hash, url, who, branch, project)
        content = '''
            project: %(project)s
            who: %(who)s
            id: %(id)s
            branch: %(branch)s
            url: %(url)s
            hash: %(hash)s
        ''' % {'id':id, 'hash':hash, 'who':who, 'project':project, 'branch':branch, 'url':url}
        sendEmail(config.sendmailto, "Gerrit Hook: Success", "Gerrit Hook: Success\n\n" + content, config.smtp_host)
    except Exception as e:
        print('Exception: ',e)
        log.error(str(e))
        content = '''
            project: %(project)s
            who: %(who)s
            id: %(id)s
            branch: %(branch)s
            url: %(url)s
            hash: %(hash)s
        ''' % {'id':id, 'hash':hash, 'who':who, 'project':project, 'branch':branch, 'url':url}
        sendEmail(config.sendmailto, "Gerrit Hook: Failure", "Gerrit Hook: Failure\n\nError: " + str(e) + "\n\n" + content, config.smtp_host)
        raise

    log.debug("Exiting change-merged hook -----------")
        
if __name__ == '__main__':
    main()
