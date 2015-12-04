#!/usr/bin/env python
"""2014 Chase Pettet <cpettet@wikimedia.org>

This script acts as an intermediary between an MTA and phabricator providing
some extra functionality and raw email piping.

* default behavior is to deliver to phabricator handler
* address routing allows redirecting an email address
  to create new tasks in project
* direct comments allows non-phabricator recognized emails to attach comments
  to a ticket for a specific project from allowed domains

Looks for configuration file: /etc/phab_epipe.conf

    [default]
    security = users
    # if 'true' will reject all email to phab
    maint = false
    # saves every message overwriting /tmp/rawmail
    save = false
    # saves particular messages from a comma
    # separated list of users
    debug = <emails_to_dump_for_debug>
    # email that phab is set to accept new tasks on
    taskcreation = <task@phab.foo.com>

    # Direct route an email to new tasks associated with
    # a project.
    [address_routing]
    <dest_email_address> = <project_name/security>

    [direct_comments_allowed]
    <project_name> = <comma_separated_list_of_allowed_email_domains>

    [phab_bot]
    # Notice attachments to direct tasks will be permissioned as the
    # phab_bot user
    root_dir = <path_on_disk_to_phabricator
    username    = <phab_user>
    certificate = <phab_user_cert>
    host        = <phab_host>

"""
import base64
import os
import re
import subprocess
import sys
import syslog
from email.parser import Parser
from email.utils import parseaddr
import ConfigParser

from phabricator import Phabricator


def extract_direct_task(list_of_dests):
    """returns a dest ticket number of available
    :param list_of_dests: list of dest email strings
    :returns: string
    """
    for dest in [m.strip() for m in list_of_dests]:
        task = re.match('^[T|t](\d+)@', dest)
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


class EmailStatusError(Exception):
    pass


def main():

    log = lambda m: output(m, verbose='-v' in sys.argv)

    # if stdin is empty we bail to avoid a loop
    # of looking for EOF that never comes
    if sys.stdin.isatty():
        raise EmailParsingError('no stdin')

    parser = ConfigParser.SafeConfigParser()
    parser_mode = 'phab_bot'
    parser.read('/etc/phab_epipe.conf')
    username = parser.get(parser_mode, 'username')
    phab = Phabricator(username=username,
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

    def sanitize_email(email):
        """make an email str worthy of crawlers
        :param email: str
        """
        if '@' not in email:
            return ''
        u, e = email.split('@')
        u = u.lstrip('<')
        return '<%s at %s>' % (u, e.split('.')[0])

    def get_proj_by_name(name):
        """return json response
        :param name: str of project name
        """
        return phab.project.query(names=[name])

    def get_proj_by_phid(phid):
        """return json response
        :param phid: str of project phid
        """
        return phab.phid.query(phids=[phid])[phid]

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
        block += "`%s`\n\n" % (subject)

        sane_body = []
        for l in body.splitlines():
            if l.strip() == '--':
                sane_body.append('> ~~')
            else:
                sane_body.append('> %s' % (l.strip(),))

        block += '\n'.join(sane_body)

        if uploads:
            block += '\n\n--------------------------\n'
            for ref in uploads:
                block += "\n{%s}" % (ref,)
        return external_user_comment(task, block)

    def mail2task(sender, src_addy, date, subject, body, project, security):
        block = "**`%s`** //%s// created via email on `%s`\n\n" % (sender,
                                                                   src_addy,
                                                                   date)

        block += '\n'.join(['> ' + s for s in body.splitlines()])
        block += '\n\n                  this task filed by anonymous email'
        project_info = get_proj_by_name(project)
        if not project_info['data']:
            raise EmailParsingError("project %s does not exist" % (project))

        # XXX: if we need direct security task filing this is where to do it
        # auxiliary contains any custom maniphest settings
        # security_dict = {"std:maniphest:security_topic": security}

        # find the first phid (we only associate one for now)
        proj_phid = project_info['data'].keys()[0]

        return phab.maniphest.createtask(title=subject,
                                         description=block,
                                         projectPHIDs=[proj_phid])

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

    def upload_file(name, data, policy):
        """ upload a base64 image hash
        :param name: str
        :param data: base64 encoded str
        :param policy: valid policy str
        """
        upload = phab.file.upload(name=name,
                                  data_base64=data,
                                  viewPolicy=policy)
        return phab.file.info(phid=upload.response).response

    def extract_payload_and_upload(payload, policy='public'):
        """ extract content and upload from MIME object
        :param payload: MIME payload object
        :return: str of created phab oject
        """
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
            upload = upload_file(name, data, policy=policy)
            return upload['objectName']

    def phab_handoff(email):
        handler = os.path.join(parser.get(parser_mode, 'root_dir'),
                               "scripts/mail/mail_handler.php")
        process = subprocess.Popen([handler], stdin=subprocess.PIPE)
        process.communicate(email)

    def extract_body_and_attached(msg):
        """ get body and payload objects

        NOTE: there has to be a better way

        :param msg: email msg type
        :return: str and list
        """
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
                            dest = str(dest_addresses)
                            raise EmailParsingError(error % (src_address,
                                                             dest))

                else:
                    log('attaching file')
                    attached.append(payload)

        else:
            body = msg.get_payload()
        return body, attached

    # If maint is true then reject all email interaction
    if defaults['maint'].lower() == 'true':
        raise EmailStatusError('Email interaction is currently disabled.')

    if '-s' in sys.argv:
        save = '/tmp/maildump'
    elif 'save' in defaults:
        save = defaults['save']
    else:
        save = False

    if 'debug' in defaults:
        defaults['debug'] = defaults['debug'].lower().split(',')

    # Reading in the message
    stdin = sys.stdin.read()

    if save:
        log('saving raw email to %s' % save)
        with open(save, 'w') as r:
            r.write(stdin)

    # ['Received', 'DKIM-Signature', 'X-Google-DKIM-Signature',
    # 'X-Gm-Message-State', 'X-Received', 'Received',
    # 'Date', 'From', 'To', 'Message-ID',
    # 'Subject', 'X-Mailer', 'MIME-Version', 'Content-Type']
    msg = Parser().parsestr(stdin)
    src_address = msg['from']
    src_name, src_addy = parse_from_string(src_address)
    dest_addresses = msg['to'].split(',')

    if msg['cc']:
        cc_addresses = msg['cc'].split(',')
    else:
        cc_addresses = []

    # Some email clients do crazy things and it is very
    # difficult to debug without the raw message.  In these (rare)
    # cases we can add the sender to debug to log
    if 'debug' in defaults:
        src = src_address.lower().strip().strip('<').strip('>')
        if src in defaults['debug']:
            with open('/tmp/%s' % (src_address + '.txt'), 'w') as r:
                r.write(stdin)

    # does this email have a direct to task addresss
    dtask = extract_direct_task(dest_addresses + cc_addresses)
    # determine if there is a reroutable address
    to_addresses = [d.split('@')[0] for d in dest_addresses]
    routed_addresses = [a for a in address_routing.keys() if a in to_addresses]

    if dtask:
        log('found direct task: %s' % (dtask,))
        body, attached = extract_body_and_attached(msg)
        userinfo = phab.user.query(usernames=[username])[0]

        if 'phid' in userinfo and userinfo['phid'].startswith('PHID'):
            policy = userinfo['phid']
        else:
            raise EmailParsingError('unknown user')

        uploads = []
        for payload in attached:
            uploads.append(extract_payload_and_upload(payload,
                                                      policy=policy))

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
            pname = get_proj_by_phid(p)['name']
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
        body, attached = extract_body_and_attached(msg)

        # If this user is known to phabricator use standard
        # email parsing logic.
        userinfo = phab.user.query(emails=[src_addy])
        if userinfo.response:
            from email.mime.image import MIMEImage
            from email.mime.multipart import MIMEMultipart
            from email.mime.text import MIMEText
            body += "\n\n#%s" % (address_routing[route_address],)
            # XXX TODO: handle MIME attachments for direct route tasks
            nmsg = MIMEMultipart()
            nmsg['From'] = src_addy
            nmsg['To'] = defaults['taskcreation']
            nmsg['subject'] = msg['subject']
            mbody = MIMEText(body, 'plain')
            nmsg.attach(mbody)
            phab_handoff(nmsg.as_string())
            return

        # XXX: handle secure uploads for routed tasks
        # uploads = []
        # for payload in attached:
        #    uploads.append(extract_payload_and_upload(payload))

        log('found routed address: %s' % (route_address,))
        if '/' in address_routing[route_address]:
            project, security = address_routing[route_address].split('/')
        else:
            project = address_routing[route_address]
            security = defaults['security']

        log(mail2task(src_name,
                      sanitize_email(src_addy),
                      msg['date'],
                      msg['subject'],
                      body,
                      project,
                      security))

    else:
        phab_handoff(stdin)

if __name__ == '__main__':
    contact = 'Please contact a WMF Phabricator admin.'

    try:
        main()
    # using this as a pipe Exim will return any error
    # output to the sender, in order to not reveal internal
    # errors we only respond directly for defined errors
    # otherwise swallow, return generic, and go for syslog
    except EmailStatusError as e:
        print "%s\n\n%s" % (e, contact)
        exit(1)
    except EmailParsingError as e:
        syslog.syslog("EmailParsingError: %s" % (str(e)))
        print "%s\n\n%s" % (e, contact)
        sys.exit(1)
    except Exception as e:
        msg = 'Error parsing message'
        syslog.syslog("%s: %s" % (msg, str(e)))
        print "%s\n\n%s" % (msg, contact)
        sys.exit(1)
