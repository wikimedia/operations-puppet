#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
  ssh-agent-proxy -- filtering proxy for ssh-agent

  Creates a UNIX domain socket that proxies connections to an ssh-agent(1)
  socket, disallowing any operations except listing identities and signing
  requests. Request signing is only permitted if group is allowed to use
  the requested public key fingerprint.

  Requirements: PyYAML (http://pyyaml.org/)

  Copyright 2015-2018 Wikimedia Foundation, Inc.
  Copyright 2015 Ori Livneh <ori@wikimedia.org>
  Copyright 2015 Tyler Cipriani <thcipriani@wikimedia.org>
  Copyright 2018 Faidon Liambotis <faidon@wikimedia.org>

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

      http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY CODE, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.

"""
import argparse
import base64
import glob
import grp
import hashlib
import logging
import logging.handlers
import os
import pwd
import select
import socket
import socketserver
import struct
import subprocess
import sys

try:
    import yaml
except ImportError:
    sys.exit(
        'Error: ssh-agent-proxy requires PyYAML (http://pyyaml.org/)\n'
        'Debian / Ubuntu: `apt-get install python3-yaml`\n'
        'RHEL / Fedora / CentOS: `yum install python-yaml`\n'
        'All others: `pip3 install PyYAML`'
    )

logger = logging.getLogger('ssh-agent-proxy')

# Defined in <socket.h>.
SO_PEERCRED = 17

# These constants are part of OpenSSH's ssh-agent protocol spec.
# See <http://api.libssh.org/rfc/PROTOCOL.agent>.
SSH2_AGENTC_REQUEST_IDENTITIES = 11
SSH2_AGENTC_SIGN_REQUEST = 13
SSH_AGENTC_REQUEST_RSA_IDENTITIES = 1
SSH_AGENT_FAILURE = 5

SSH_AGENT_OLD_SIGNATURE = 1
SSH_AGENT_RSA_SHA2_256 = 2
SSH_AGENT_RSA_SHA2_512 = 4

s_message_header = struct.Struct('!LB')
s_flags = struct.Struct('!L')
s_ucred = struct.Struct('2Ii')


class SshAgentProtocolError(OSError):
    """Custom exception class for protocol errors."""


def unpack_variable_length_string(buffer, offset=0):
    """Read a variable-length string from a buffer. The first 4 bytes are the
    big-endian unsigned long representing the length of the string."""
    fmt = 'xxxx%ds' % struct.unpack_from('!L', buffer, offset)
    string, = struct.unpack_from(fmt, buffer, offset)
    return string, offset + struct.calcsize(fmt)


def get_key_fingerprints(key_dir):
    """Look up the key fingerprints for all keys held by keyholder"""
    keymap = {}
    for fname in glob.glob(os.path.join(key_dir, '*.pub')):
        line = subprocess.check_output(
            ['/usr/bin/ssh-keygen', '-lf', fname], universal_newlines=True)
        bits, fingerprint, note = line.split(' ', 2)
        keyfile = os.path.splitext(os.path.basename(fname))[0]
        keymap[keyfile] = fingerprint.replace(':', '')
    logger.info('Successfully loaded %d key(s)', len(keymap))
    return keymap


def get_key_perms(auth_dir, key_dir):
    """Recursively walk `auth_dir`, loading YAML configuration files."""
    key_perms = {}
    fingerprints = get_key_fingerprints(key_dir)
    for fname in glob.glob(os.path.join(auth_dir, '*.y*ml')):
        with open(fname) as yml:
            for group, keys in yaml.safe_load(yml).items():
                for key in keys:
                    if key not in fingerprints:
                        logger.info('Fingerprint not found for key %s', key)
                        continue
                    fingerprint = fingerprints[key]
                    key_perms.setdefault(fingerprint, set()).add(group)
    return key_perms


class SshAgentProxyServer(socketserver.ThreadingUnixStreamServer):
    """A threaded server that listens on a UNIX domain socket and handles
    requests by filtering them and proxying them to a backend SSH agent."""

    def __init__(self, server_address, agent_address, key_perms):
        super().__init__(server_address, SshAgentProxyHandler)
        self.agent_address = agent_address
        self.key_perms = key_perms

    def handle_error(self, request, client_address):
        super().handle_error(request, client_address)
        exc_type, exc_value, exc_traceback = sys.exc_info()
        logger.error('[%s] %s', exc_type, exc_value)


class SshAgentProxyHandler(socketserver.BaseRequestHandler):
    """This class is responsible for handling an individual connection
    to an SshAgentProxyServer."""

    def get_peer_credentials(self, sock):
        """Return the user and group name of the peer of a UNIX socket."""
        ucred = sock.getsockopt(socket.SOL_SOCKET, SO_PEERCRED, s_ucred.size)
        _, uid, gid = s_ucred.unpack(ucred)
        user = pwd.getpwuid(uid).pw_name
        groups = {grp.getgrgid(g).gr_name for g in os.getgrouplist(user, gid)}
        return user, groups

    def setup(self):
        """Set up a connection to the backend SSH agent backend."""
        self.backend = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
        self.backend.setblocking(False)
        self.backend.connect(self.server.agent_address)

    def recv_message(self, sock):
        """Read a message from a socket."""
        header = sock.recv(s_message_header.size, socket.MSG_WAITALL)
        try:
            size, code = s_message_header.unpack(header)
        except struct.error:
            return None, b''
        message = sock.recv(size - 1, socket.MSG_WAITALL)
        return code, message

    def send_message(self, sock, code, message=b''):
        """Send a message on a socket."""
        header = s_message_header.pack(len(message) + 1, code)
        sock.sendall(header + message)

    def handle_client_request(self, code, message):
        """Read data from client and send to backend SSH agent."""
        if code in (SSH2_AGENTC_REQUEST_IDENTITIES,
                    SSH_AGENTC_REQUEST_RSA_IDENTITIES):
            if message:
                raise SshAgentProtocolError('Trailing bytes')
            self.send_message(self.backend, code)

        elif code == SSH2_AGENTC_SIGN_REQUEST:
            # disable E999 as CI checks with python2 T184435
            key_blob, *_ = self.parse_sign_request(message)  # noqa: E999
            key_digest_md5 = hashlib.md5(key_blob).hexdigest()
            # disable E999 as CI checks with python2 T184435
            key_digest_sha256 = (b'SHA256' + base64.b64encode(hashlib.sha256(
                key_blob).digest()).rstrip(b'=')).decode('utf-8')  # noqa: E999
            user, groups = self.get_peer_credentials(self.request)
            if groups & self.server.key_perms.get(key_digest_md5, set()).union(
                    self.server.key_perms.get(key_digest_sha256, set())):
                logger.info('Granting agent sign request for user %s', user)
                self.send_message(self.backend, code, message)
            else:
                logger.info('Refusing agent sign request for user %s', user)
                self.send_message(self.request, SSH_AGENT_FAILURE)

        else:
            logger.debug('Unknown request code %d, refusing', code)
            self.send_message(self.request, SSH_AGENT_FAILURE)

    def handle(self):
        """Handle a new client connection by shuttling data between the client
        and the backend."""
        while 1:
            rlist, *_ = select.select((self.backend, self.request), (), (), 1)
            if self.backend in rlist:
                code, message = self.recv_message(self.backend)
                self.send_message(self.request, code, message)
            if self.request in rlist:
                code, message = self.recv_message(self.request)
                if not code:
                    return
                self.handle_client_request(code, message)

    def parse_sign_request(self, message):
        """Parse the payload of an SSH2_AGENTC_SIGN_REQUEST into its
        constituent parts: a key blob, data, and a uint32 flag."""
        key_blob, offset = unpack_variable_length_string(message)
        data, offset = unpack_variable_length_string(message, offset)
        flags, = s_flags.unpack_from(message, offset)

        if offset + s_flags.size != len(message):
            raise SshAgentProtocolError('Trailing bytes')

        # this is not the right way to be parsing flags, as in theory they can
        # coexist; in practice the existing ones cannot meaningfully coexist so
        # that will do for now. In Python >= 3.6, they should be replaced with
        # the builtin class Flag.
        if flags not in (0, SSH_AGENT_OLD_SIGNATURE,
                         SSH_AGENT_RSA_SHA2_256, SSH_AGENT_RSA_SHA2_512):
            raise SshAgentProtocolError('Unrecognized flags 0x%X' % flags)

        return key_blob, data, flags


def parse_args():
    """Parse and return the parsed command line arguments."""
    parser = argparse.ArgumentParser(
        description='filtering proxy for ssh-agent',
        formatter_class=argparse.ArgumentDefaultsHelpFormatter
    )
    parser.add_argument(
        '--debug',
        action='store_true',
        help='Debug mode: log to stdout and be more verbose',
    )
    parser.add_argument(
        '--bind',
        default='/run/keyholder/proxy.sock',
        help='Bind the proxy to the domain socket at this address'
    )
    parser.add_argument(
        '--connect',
        default='/run/keyholder/agent.sock',
        help='Proxy connects to the ssh-agent socket at this address'
    )
    parser.add_argument(
        '--key-dir',
        default='/etc/keyholder.d',
        help='directory with SSH keys'
    )
    parser.add_argument(
        '--auth-dir',
        default='/etc/keyholder-auth.d',
        help='directory with YAML configuration files'
    )
    return parser.parse_args()


def setup_logging(debug):
    """Setup logging format and level."""
    if debug:
        logger.setLevel(logging.DEBUG)
        stream_handler = logging.StreamHandler()
        fmt = logging.Formatter('%(asctime)s %(levelname)s: %(message)s')
        stream_handler.setFormatter(fmt)
        logger.addHandler(stream_handler)
    else:
        logger.setLevel(logging.INFO)
        syslog_handler = logging.handlers.SysLogHandler(
            address='/dev/log',
            facility='auth',
        )
        fmt = logging.Formatter('%(name)s[%(process)d]: %(message)s')
        syslog_handler.setFormatter(fmt)
        logger.addHandler(syslog_handler)


def main():
    """Main entry point; runs forever."""
    args = parse_args()
    setup_logging(args.debug)

    perms = get_key_perms(args.auth_dir, args.key_dir)
    logger.info('Initialized and serving requests')

    server = SshAgentProxyServer(args.bind, args.connect, perms)

    try:
        server.serve_forever()
    except (SystemExit, KeyboardInterrupt):
        logger.info('Shutting down')
    server.server_close()


if __name__ == '__main__':
    main()
