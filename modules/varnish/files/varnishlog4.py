# -*- coding: utf-8 -*-

"""
  varnishlog4.py
  ~~~~~~~~~~~~~~

  varnishlog4.varnishlog calls a given function for every VSL entry that
  matches filters provided in vsl_args.

  Usage:

    from varnishlog4 import varnishlog
    def my_callback(transaction_id, tag, value, remote_party):
      print(transaction_id, tag, value, remote_party)

    varnishlog(
        [
            ('n', 'frontend'),
            ('i', 'ReqURL'),
            ('c', '')
        ],
    my_callback)

  This module depends on python-varnishapi:
  https://github.com/xcir/python-varnishapi


  Copyright 2016 Emanuele Rocca
  Copyright 2016 Wikimedia Foundation, Inc.

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

      http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
"""

import time
import signal
import logging

import varnishapi


class VarnishCallbackHandler:

    def __init__(self, args, callback):
        """Set up a callback handler. The callback function will be executed
        for all transactions matching the given args.

        args must be a list of varnishlog arguments such as:
            [ '-i', 'ReqURL', '-n', 'frontend']

        callback needs to be a function with the following signature:
            callback(transaction_id, tag, value, remote_party)
        """
        self.vap = varnishapi.VarnishLog(args)
        self.callback = callback

        if self.vap.error:
            raise Exception(self.vap.error)

        signal.signal(signal.SIGINT, self.fini)
        signal.signal(signal.SIGTERM, self.fini)
        self.keep_running = True

    def fini(self, signum=None, frame=None):
        """Exit gracefully"""
        self.keep_running = False
        self.vap.Fini()

    def execute(self):
        """Loop and execute callback"""
        while self.keep_running:
            ret = self.vap.Dispatch(self.vap_callback)
            if ret == 0:
                time.sleep(0.1)

    def vap_callback(self, vap, cbd, priv):
        """Callback passed to varnishapi.VarnishLog.Dispatch.

        cbd is a dictionary populated by varnishapi.VarnishLog.__callBack with
        data such as:

        {
            [...]
            'vxid_parent': 0,
            'vxid': 6,
            'tag': 20L,
            'data': 'User-Agent: curl/7.47.0\x00',
            'type': 'c',
        }

        Here in vap_callback we decode the VSL tag and map the type to client,
        backend, or None. Finally, we call the function passed as an argument
        to varnishlog4.varnishlog with the decoded values. For example:

        self.callback(transaction_id=32770,
                      tag="ReqHeader",
                      value="User-Agent: curl/7.47.0",
                      remote_party="client")
        """
        transaction_id = cbd['vxid']
        tag = vap.VSL_tags[cbd['tag']]

        # Remove trailing NULL byte
        value = cbd['data'].rstrip('\x00')

        remote_type = cbd['type']

        remote_party = {
            "c": "client",
            "b": "backend",
        }.get(remote_type, None)

        self.callback(transaction_id, tag, value, remote_party)


def parse_varnishlog_args(args):
    """Expand the given list of (option, argument) 2-tuples, in a list of
    strings suitable for varnishapi.VarnishLog:

    [ ('i', 'ReqURL'), ('c', None), ('i', 'ReqMethod') ] ->
            [ '-i', 'ReqURL', 'c', '-i', 'ReqMethod' ]"""
    vapi = varnishapi.VarnishAPI()

    parsed_args = []
    for switch, value in args:
        # eg: switch = "i", value = "ReqUrl"
        if switch == "i" and value not in vapi.VSL_tags_rev:
            logging.warning("Unknown Tag: %s", value)
            continue

        parsed_args.append("-%s" % switch)
        if value:
            parsed_args.append(value)

    return parsed_args


def varnishlog(vsl_args, callback):
    """Register the given callback function and execute it for all varnish log
    records matching the given VSL args.

    vsl_args must be a list of 2-tuples such as:
        [ ( 'i', 'ReqURL' ), ('n', 'frontend') ]

    See varnishlog(1) for the list of available options.

    callback needs to be a function with the following signature:
        callback(transaction_id, tag, value, remote_party)
    """
    vlog = VarnishCallbackHandler(
        parse_varnishlog_args(vsl_args), callback)

    vlog.execute()

if __name__ == '__main__':
    args = [
        ('c', None),
        ('i', 'RespStatus'),
        ('i', 'ReqHeader'),
        ('i', 'RespHeader'),
        ('i', 'ReqURL'),
    ]

    def print_tags_callback(transaction_id, tag, value, remote_party):
        print("transaction_id: %s, tag: %s, value: %s, remote_party: %s" % (
            transaction_id, tag, value, remote_party))

    varnishlog(args, print_tags_callback)
