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
import base64
from email.parser import Parser
from email.utils import parseaddr
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


class EmailParsingError(Exception):
    pass


def main():

    save = '-s' in sys.argv
    log = lambda m: output(m, verbose='-v' in sys.argv)

    # if stdin is empty we bail to avoid a loop
    # of looking for EOF that never comes
    if sys.stdin.isatty():
        raise EmailParsingError('no stdin')

    parser = ConfigParser.SafeConfigParser()
    parser_mode = 'phab_bot'
    parser.read('/etc/phab_epipe.conf')
    phab = Phabricator(username=parser.get(parser_mode, 'username'),
                       certificate=parser.get(parser_mode, 'certificate'),
                       host=parser.get(parser_mode, 'host'))

    defaults = {}
    for name, value in parser.items('default'):
        defaults[name] = value

    address_routing = {}
    for name, value in parser.items('address_routing'):
        address_routing[name] = value

    direct_com = {}
    for name, value in parser.items('direct_comments_allowed'):
        direct_com[name] = value.split(',')

    def get_proj_by_name(name):
        """return json response
        :param name: str of project name
        """
        return phab.project.query(names=[name])

    def get_proj_phid_by_id(pid):
        """return project name by project id
        :param pid: int project id
        :returns: string
        """
        return phab.project.query(ids=[pid])['data'].keys()[0]

    def external_user_comment(task, text):
        """update a task with a comment by id
        :param task: int id
        :param email: address of source user
        :param text: main comment string
        :returns: json
        """
        return phab.maniphest.update(id=task, comments=text)

    def mail2comment(task, name, date, subject, body, uploads):
        """update a task with a comment by id
        :param task: int id
        :param name: sender str
        :param date: str
        :param subject: str
        :param body: st
        :param uploads: list of phab attachment id's
        :returns: json
        """
        block = "**`%s`** replied via email on `%s`\n\n" % (name, date)
        block += "__Subject__: %s\n\n" % (subject)
        block += '\n'.join(['> ' + s for s in body.splitlines()])
        if uploads:
            block += '\n\n\n--------------------------\n'
            for ref in uploads:
                block += "\n    {%s}" % (ref,)
        return external_user_comment(task, block)

    def mail2task(sender, date, subject, body, project, security):
        block = "**`%s`** created via email on `%s`\n\n" % (sender, date)
        block += '\n'.join(['> ' + s for s in body.splitlines()])
        project_info = get_proj_by_name(project)

        if not project_info['data']:
            raise EmailParsingError("project %s does not exist" % (project))

        # auxiliary contains any custom maniphest settings
        security_dict = {"std:maniphest:security_topic": security}
        # find the first phid (we only associate one for now)
        proj_phid = project_info['data'].keys()[0]
        return phab.maniphest.createtask(title=subject,
                                         description=block,
                                         projectPHIDs=[proj_phid],
                                         auxiliary=security_dict)

    def parse_from_string(from_str):
        """ parses from elements
        :param: src string
        :returns: tuple
        https://docs.python.org/2/library/email.util.html
        """
        name, addy = parseaddr(from_str)
        if not name:
            name = addy.split('@')[0]
        return name, addy

    def upload_file(name, data):
        upload = phab.file.upload(name=name, data_base64=data)
        return phab.file.info(phid=upload.response).response

    stdin = sys.stdin.read()

    if save:
        dump = '/tmp/rawmail'
        log('saving raw email to %s' % dump)
        with open(dump, 'w') as r:
            r.write(stdin)

    # ['Received', 'DKIM-Signature', 'X-Google-DKIM-Signature',
    # 'X-Gm-Message-State', 'X-Received', 'Received',
    # 'Date', 'From', 'To', 'Message-ID',
    # 'Subject', 'X-Mailer', 'MIME-Version', 'Content-Type']
    msg = Parser().parsestr(stdin)
    src_address = msg['from']
    src_name, src_addy = parse_from_string(src_address)
    dest_addresses = msg['to'].split(',')

    attached = []
    # https://docs.python.org/2/library/email.message.html
    if msg.is_multipart():
        for payload in msg.get_payload():
            log('content type: %s' % (payload.get_content_type(),))
            if payload.get_content_type() == 'text/plain':
                body = payload.get_payload()
            elif payload.get_content_type() == 'multipart/alternative':
                msgparts = payload.get_payload()
                if not isinstance(msgparts, list):
                    body = 'unknown body format'
                    continue
                else:
                    for e in msgparts:
                        known_body_types = ['text/plain']
                        # text/plain; charset="utf-8"
                        # Inconsistent content-types so we
                        # try to match only basic string
                        type = e['Content-Type'].split(';')[0]
                        if type in known_body_types:
                            body = e.get_payload()
                            break
                    else:
                        err = 'Unknown email body format: from %s to %s'
                        raise EmailParsingError(error % (src_address,
                                                         str(dest_addresses)))

            else:
                log('attaching file')
                attached.append(payload)

    else:
        body = msg.get_payload()

    uploads = []
    for payload in attached:

        name = None
        # Some attachments have the field but it is None type
        if not name and 'Content-Description' in payload:
            name = payload['Content-Description']

        if not name and 'Content-Disposition' in payload:
            namex = re.search('name=\"(.*)\"', payload['Content-Type'])
            if namex:
                name = namex.group(1)

        if not name and 'Content-Disposition' in payload:
            fnamex = re.search('filename=(.*)', payload['Content-Disposition'])
            if fnamex:
                name = fnamex.group(1)

        if name:
            data = payload.get_payload()
            upload = upload_file(name, data)
            uploads.append(upload['objectName'])

    # does this email have a direct to task addresss
    dtask = extract_direct_task(dest_addresses)

    # determine if there is a reroutable address
    to_addresses = [d.split('@')[0] for d in dest_addresses]
    routed_addresses = [a for a in address_routing.keys() if a in to_addresses]

    if dtask:
        log('found direct task: %s' % (dtask,))
        # extra check for address validity for this process
        if src_address.count('@') > 1:
            error = 'invalid source address: %s' % (src_address,)
            raise EmailParsingError(error)

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
            raise EmailParsingError('no matching direct task allowed project')

        src_domain = src_addy.split('@')[1]
        if src_domain not in direct_com[dtask_match] and not '*':
            error = 'direct comment not allowed from this domain'
            raise EmailParsingError(error)

        log(mail2comment(dtask,
                         src_name,
                         msg['date'],
                         msg['subject'],
                         body,
                         uploads))

    elif routed_addresses:
        route_address = routed_addresses[0]
        log('found routed address: %s' % (route_address,))
        if '/' in address_routing[route_address]:
            project, security = address_routing[route_address].split('/')
        else:
            project = address_routing[route_address]
            security = defaults['security']

        log(mail2task(src_name,
                      msg['date'],
                      msg['subject'],
                      body,
                      project,
                      security))
    else:
        log('found phab default')
        handler = os.path.join(parser.get(parser_mode, 'root_dir'),
                               "scripts/mail/mail_handler.php")
        process = subprocess.Popen([handler, parser.get(parser_mode, 'env')],
                                   stdin=subprocess.PIPE)
        process.communicate(stdin)


if __name__ == '__main__':
    contact = 'Please contact a WMF Phabricator admin.'

    try:
        main()
    # using this as a pipe Exim will return any error
    # output to the sender, in order to not reveal internal
    # errors we only respond directly for defined errors
    # otherwise swallow, return generic, and go for syslog
    except EmailParsingError as e:
        syslog.syslog("EmailParsingError: %s" % (str(e)))
        print "%s\n\n%s" % (e, contact)
        sys.exit(1)
    except Exception as e:
        msg = 'Error parsing message'
        syslog.syslog("%s: %s" % (msg, str(e)))
        print "%s\n\n%s" % (msg, contact)
        sys.exit(1)
