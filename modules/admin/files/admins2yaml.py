#!/usr/bin/env python

import re, time, sys, yaml, os

help = """

    => This is a oneoff for migration from admins.pp to a structured format.  It is ugly, it is brutish...it may also work.

    prints yaml to stdout

    %s <path to admins.pp> [groups (display not default groups)] [-v for verbose]

    """ % (sys.argv[0])

if '-h' in sys.argv:
    print help
    sys.exit(0)

vmarker = '-v'
verbose = True if vmarker in sys.argv else False
if vmarker in sys.argv:
    sys.argv.pop(sys.argv.index(vmarker))

if len(sys.argv) < 2:
    print help
    sys.exit(1)

adminsfile = sys.argv[1]
if not os.path.exists(adminsfile):
    print 'path does not exist!'
    print help
    sys.exit(1)
    
def printv(msg):
    if verbose:
        print msg

users = {}
groups = {}
splitter = 'class'
with open(adminsfile) as f:
    for i in f.read().split(splitter):
        printv('=> %s' % i)

        #groups:
        #  ops:
        #    ensure: 'present'
        #    gid: 580
        #    members:
        #      - test1
        #      - test2
        group = {}
        ginfo = re.search("admins::(\S+)\s+{", i)
        if ginfo:
            printv('group info! %s' % ginfo.groups())
            gname = ginfo.groups()[0]
            gusers = re.findall('accounts::(\S*)', i)
            gusers = map(lambda s: s.strip().strip(','), gusers)
            group['ensure'] = 'present'
            printv('setting ensure to present for %s' % gname)
            group['members'] = gusers
            printv('%s members: %s (%d)' % (gname, gusers, len(gusers)))
            groups[gname] = group

        #users:
        #  tparscal:
        #    ensure: present
        #    gid: 500
        #    realname: Trevor Parscal
        #    ssh_keys: []
        #    uid: 541
        user = {}
        uinfo = re.search("\$username\s=\s'(.*)'", i)
        if uinfo:
           
            printv('________________________________user_____________________________')
            printv(uinfo.groups()[0])
            username = uinfo.groups()[0]

            if re.search('enabled\s+=\s+false', i):
                printv('%s as enabled=false' % (username))
                user['ensure'] = 'absent'
            else:
                user['ensure'] = 'present'

            user['name'] = username

            realname = re.search("\$realname\s=\s'(.*)'", i)
            uid = re.search("\$uid\s+=\s'(.*)'", i)

            realname_str = realname.groups()[0]
            #yaml/python2.7/ruby and unicode...screw you yaml
            #this works at least
            if 'Niklas Laxstr' in realname_str:
                user['realname'] = unicode(realname.groups()[0], "utf-8")
            else:
                user['realname'] = realname.groups()[0]

            user['uid'] =  int(uid.groups()[0])
            user['gid'] = 500
            printv(user['realname'])
            printv(user['uid'])
            printv(user['gid'])


            if 'ssh_authorized_key' in i:
                ssh_keys = []
                printv('-----------------begin keys------------------')
                key_stanzas = i.split('ssh_authorized_key {')
                for k in key_stanzas:
                    printv('key stanza post split: %s' % (k))
                try:
                    key_stanzas = key_stanzas[1]
                    printv('key stanzas fina %s' % key_stanzas)
                except IndexError as e:
                    printv("Ignoring key stanza for block %s" % (i))
                    continue
                #non standard methods for adding multiple keys means fun here
                key_split = ';' if ';' in key_stanzas else '}'
                printv('key splitter used: %s' % key_split)
                key_splitup = key_stanzas.split(key_split)
                for index, block in enumerate(key_splitup):
                    #the intention is to manage _all_ keys through puppet
                    #thus we ignore absented a non-explicity is absent
                    if 'key' in block and not "ensure => 'absent'" in block:
                        printv('trying to extract key from: %s' % block)
                        comment = re.search("\'(.*)\':", block)
                        type = re.search("type\s+=>\s+'(.*)'", block)
                        key = re.search("key\s+=>\s+'(.*)'", block)
                        comment = comment.groups()[0].strip() if comment else ''
                        #unclosed quotes in comments become illegal chars
                        comment = comment.replace("'", '')
                        comment = comment.replace('"', '')

                        if type and key:
                            printv('\n______extracted key_____:\n\n %s %s %s\n' % (type.groups()[0].strip(),
                                                                                   key.groups()[0].strip(),
                                                                                   comment))
                            ssh_keys.append("%s %s %s" % (type.groups()[0].strip(),
                                                          key.groups()[0].strip(), comment))

                    user['ssh_keys'] = ssh_keys
                printv('-----------------end keys------------------')

            users[username] = user
        printv('____________________________________________________________________________')
        printv('________________________________section_____________________________________')

output = {}
absent = {}

if 'groups' not in sys.argv:
    groups = {}

groups['absent'] = {'description': 'meta group for absented users', 'members': []}
groups['ops'] = {'description': 'include everywhere ops folks', 'members': []}
output['groups'] = groups

output['users'] = users
print yaml.dump(output)
