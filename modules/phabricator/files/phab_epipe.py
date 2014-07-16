#!/usr/bin/env python
"""2014 Chase Pettet <cpettet@wikimedia.org>

This script acts as an intermediary between an MTA and phabricator providing
some extra functionality and raw email piping.

* default behavior is to deliver to phabricator handler
* address routing allows redirecting an email address
  to create new tasks in project
* direct comments allows non-phabricator recognized emails to attach comments
  to a ticket for a specific project from allowed domains

-> custom attachments to be handled later by direct attach script

Looks for configuration file: /etc/phab_epipe.conf

    [address_routing]
    <dest_email_address> = <project_id_to_route_for_task_creation>

    [direct_comments_allowed]
    <project_name> = <comma_separated_list_of_allowed_email_domains>

    [phab_bot]
    root_dir = <path_on_disk_to_phabricator
    env = <phab_env>
    username    = <phab_user>
    certificate = <phab_user_cert>
    host        = <phab_host>
"""
import os
import re
import sys
import subprocess
import syslog
from email.parser import Parser
import ConfigParser

from phabricator import Phabricator


def extract_direct_task(list_of_dests):
    """returns a dest ticket number of available
    :param list_of_dests: list of dest email strings
    :returns: string
    """
    for dest in list_of_dests:
        task = re.match('^T(\d+)@', dest)
        if task:
            return int(task.group(1))
    return ''


def output(msg, verbose):
    msg = str(msg)
    if verbose is True:
        syslog.syslog(msg)
        print '-> ', msg


def main():

    save = '-s' in sys.argv
    log = lambda m: output(m, verbose='-v' in sys.argv)

    # if stdin is empty we bail to avoid a loop
    # of looking for EOF that never comes
    if sys.stdin.isatty():
        log('no stdin')
        exit(1)

    parser = ConfigParser.SafeConfigParser()
    parser_mode = 'phab_bot'
    parser.read('/etc/phab_epipe.conf')
    phab = Phabricator(username=parser.get(parser_mode, 'username'),
                       certificate=parser.get(parser_mode, 'certificate'),
                       host=parser.get(parser_mode, 'host'))

    address_routing = {}
    for name, value in parser.items('address_routing'):
        address_routing[name] = value

    direct_com = {}
    for name, value in parser.items('direct_comments_allowed'):
        direct_com[name] = value.split(',')

    def get_proj_phid_by_id(pid):
        """return project name by project id
        :param pid: int project id
        :returns: string
        """
        return phab.project.query(ids=[pid])['data'].keys()[0]

    def external_user_comment(task, email, text):
        """update a task with a comment by id
        :param task: int id
        :param email: address of source user
        :param text: main comment string
        :returns: json
        """
        external_user_comment_body = """[%s](mailto: %s)\n>%s"""
        comment = external_user_comment_body % (email, email, text)
        return phab.maniphest.update(id=task, comments=comment)

    stdin = sys.stdin.read()

    if save:
        dump = '/tmp/rawmail'
        log('saving raw email to %s' % dump)
        with open(dump, 'w') as r:
            r.write(stdin)

    msg = Parser().parsestr(stdin)
    src_address = msg['from']
    dest_addresses = msg['to'].split(',')

    # https://docs.python.org/2/library/email.message.html
    if msg.is_multipart():
        for payload in msg.get_payload():
            if payload.get_content_type() == 'text/plain':
                body = payload.get_payload()
    else:
        body = msg.get_payload()

    # does this email have a direct to task addresss
    dtask = extract_direct_task(dest_addresses)

    # determine if there is a reroutable address
    to_addresses = [d.split('@')[0] for d in dest_addresses]
    routed_addresses = [a for a in address_routing.keys() if a in to_addresses]

    if dtask:
        log('found direct task: %s' % (dtask,))
        # extra check for address validity for this process
        if src_address.count('@') > 1:
            log('invalid source address')
            return

        # list of phid's for associated projects
        task_info = phab.maniphest.info(task_id=dtask)
        proj_info = task_info['projectPHIDs']

        # determine if task has an associate project
        dtask_match = None
        for p in proj_info:
            pname = phab.phid.info(phid=p)['name']
            if pname in direct_com.keys():
                dtask_match = pname

        if dtask_match is None:
            log('no matching direct task allowed project')
            return

        if not src_address.split('@')[1] in direct_com[dtask_match]:
            log('direct comment not allowed from this domain')
            return

        log(external_user_comment(dtask, src_address, body))

    elif routed_addresses:
        route_address = routed_addresses[0]
        log('found routed address: %s' % (route_address,))
        project_id = get_proj_phid_by_id(address_routing[route_address])
        log(phab.maniphest.createtask(title=msg['subject'],
                                      description=">%s" % body,
                                      projectPHIDs=[project_id]))
    else:
        log('found phab default')
        handler = os.path.join(parser.get(parser_mode, 'root_dir'),
                               "scripts/mail/mail_handler.php")
        process = subprocess.Popen([handler, parser.get(parser_mode, 'env')],
                                   stdin=subprocess.PIPE)
        process.communicate(stdin)

if __name__ == '__main__':
    main()
