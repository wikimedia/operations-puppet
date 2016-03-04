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

  This module uses python-varnishapi: https://github.com/xcir/python-varnishapi

"""

import time

import varnishapi


class VarnishCallbackHandler:

    def __init__(self, args, callback):
        """args = [ '-i', 'ReqURL', '-n', 'frontend' ]"""
        self.vap = varnishapi.VarnishLog(args)
        self.callback = callback

        if self.vap.error:
            raise Exception(self.vap.error)

    def fini(self):
        self.vap.Fini()

    def execute(self):
        while True:
            ret = self.vap.Dispatch(self.vap_callback)
            if ret == 0:
                time.sleep(0.1)

    def vap_callback(self, vap, cbd, priv):
        transaction_id = cbd['vxid']
        tag = vap.VSL_tags[cbd['tag']]
        value = cbd['data']
        remote_type = cbd['type']

        remote_party = {
            "c": "client",
            "b": "backend",
        }.get(remote_type, None)

        self.callback(transaction_id, tag, value, remote_party)


def __tag_exists(tag):
    util = varnishapi.VSLUtil()
    return util.tag2Var(tag, ": ")["key"] != ""


def parse_varnishlog_args(args):
    """ [ ('i', 'ReqURL'), ('c', None), ('i', 'ReqMethod') ] ->
            [ '-i', 'ReqURL', 'c', '-i', 'ReqMethod' ]"""
    parsed_args = []
    for switch, value in args:
        # eg: switch = "i", value = "ReqUrl"
        if switch == "i" and not __tag_exists(value):
            print "Unknown Tag:", value
            continue

        parsed_args.append("-%s" % switch)
        if value:
            parsed_args.append(value)

    return parsed_args


def varnishlog(vsl_args, callback):
    vlog = VarnishCallbackHandler(
            parse_varnishlog_args(vsl_args), callback)

    try:
        vlog.execute()
    except KeyboardInterrupt:
        vlog.fini()

if __name__ == '__main__':
    args = [
        ('c', None),
        ('i', 'RespStatus'),
        ('i', 'ReqHeader'),
        ('i', 'RespHeader'),
        ('i', 'ReqURL'),
    ]

    def print_tags_callback(transaction_id, tag, value, remote_party):
        print "transaction_id: %s, tag: %s, value: %s, remote_party: %s" % (
                transaction_id, tag, value, remote_party)

    varnishlog(args, print_tags_callback)
