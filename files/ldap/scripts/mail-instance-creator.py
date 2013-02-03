#!/usr/bin/python

#####################################################################
### THIS FILE IS MANAGED BY PUPPET
### puppet:///files/ldap/scripts/mail-instance-creator.py
#####################################################################


import urllib
import os

from xml.dom import minidom
from optparse import OptionParser
from socket import gethostname


def extracttemplate(wikiaddress, msg):
    dom = minidom.parse(urllib.urlopen(wikiaddress +
                        'api.php?' + urllib.urlencode((
                            ('action', 'expandtemplates'),
                            ('text', '{{msgnw:%s}}' % msg),
                            ('format', 'xml')))))
    dom.getElementsByTagName("expandtemplates")[0].firstChild.data


def main():
    import sys
    parser = OptionParser(conflict_handler="resolve")
    myself = sys.argv[0]
    parser.set_usage(myself +
                     " <from-email-address> <to-email-address>" +
                     " <languagecode> <wikiaddress>" +
                     "\n\n\texample: mail-instance-creator.py" +
                     " 'test@example.com' " +
                     "'es' 'http://example.com/w/'")

    (options, args) = parser.parse_args()

    if len(args) != 4:
        parser.error(myself + " expects exactly four arguments.")

    fromaddress = args[0]
    toaddress = args[1]
    lang = args[2]
    wikiaddress = args[3]
    subjectmsg = "mediawiki:openstackmanager-email-subject/" + lang
    bodymsg = "mediawiki:openstackmanager-email-body/" + lang
    (subject, body) = [extracttemplate(wikiaddress, s)
                       for s in (subjectmsg, bodymsg)]
    body = body + ' ' + gethostname()
    sendmail_location = "/usr/sbin/sendmail"  # sendmail location
    p = os.popen("%s -t" % sendmail_location, "w")
    p.write("From: %s\n" % fromaddress)
    p.write("To: %s\n" % toaddress)
    p.write("Subject: %s\n" % subject)
    p.write("\n")  # blank line separating headers from body
    p.write(body)
    status = p.close()
    return status

if __name__ == "__main__":
    main()
