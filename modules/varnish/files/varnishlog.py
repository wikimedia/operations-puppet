# -*- coding: utf-8 -*-
"""
  varnishlog.py
  ~~~~~~~~~~~~~

  Python 2 and 3 bindings for the Varnish shared log API.
  This uses ctypes to interface with the Varnish C API,
  and abstracts away those details.

  Usage:

    from varnishlog import varnishlog
    def my_callback(transaction_id, tag, value, remote_party):
      print(transaction_id, tag, value, remote_party)

    varnishlog(
        [
            ('n', 'frontend'),
            ('i', 'RxMethod'),
            ('c', '')
        ],
        my_callback
    ])

  In the callback, remote_party will either be 'client',
  'backend', or None.


  Copyright 2015
      Ori Livneh <ori@wikimedia.org>,
      Andrew Otto <otto@wikimedia.org>

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

      http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.

  Authors: Ori Livneh and Andrew Otto

"""
import ctypes
import ctypes.util
import functools
import unittest
import sys


varnishapi_so = ctypes.util.find_library('varnishapi')
if varnishapi_so is None:
    raise OSError('Unable to locate varnishapi library.')
varnishapi = ctypes.CDLL(varnishapi_so)
varnishapi.VSM_New.restype = ctypes.c_void_p

VSL_handler_f = ctypes.CFUNCTYPE(ctypes.c_int, ctypes.c_void_p, ctypes.c_uint,
                                 ctypes.c_uint, ctypes.c_uint, ctypes.c_uint,
                                 ctypes.POINTER(ctypes.c_char),
                                 ctypes.c_ulonglong)

# Index of Varnish log tags ('RxURL', 'ReqEnd', etc.)
VSL_Tags = (ctypes.c_char_p * 256).in_dll(varnishapi, 'VSL_tags')

# This flag indicates that the log record was generated as a result
# of communication with a client. Defined in varnishapi.h.
VSL_S_CLIENT = 1

# This flag indicates that the log record was generated as a result
# of communication with a backend server. Defined in varnishapi.h.
VSL_S_BACKEND = 2


def varnishlog(vsl_args, callback):
    """
    Calls callback for every VSL entry that matches filters
    provided in vsl_args.

    Args:
        vsl_args: List of tuples of the form (arg, value)
        callback: function that takes these arguments:
                  (tag, value, transaction_id, remote_party)
    """
    vd = varnishapi.VSM_New()
    varnishapi.VSL_Setup(vd)

    # Initialize with provided vsl_args
    for (arg, value) in vsl_args:
        arg_value = value.encode('utf-8') if value is not None else value
        if varnishapi.VSL_Arg(vd, ord(arg), arg_value) != 1:
            raise OSError('VSL_Arg(vd, "%s", "%s")' % (arg, value))

    if varnishapi.VSL_Open(vd, 1) != 0:
        raise OSError('VSL_Open(vd, 1)')

    def _vsl_handler(priv, tag_id, fd, length, spec, ptr, bitmap):
        tag = VSL_Tags[tag_id]
        record = ctypes.string_at(ptr, length)

        # Translate spec to either 'client', 'backend' or None.
        remote_party = {
            VSL_S_CLIENT:  'client',
            VSL_S_BACKEND: 'backend',
        }.get(spec, None)

        # Call the provided callback
        callback(fd, tag, record, remote_party)
        return 0

    # This will call _vsl_handler for every VSL entry,
    # which will in turn call the provided callback
    # with pythonic arguments.
    varnishapi.VSL_Dispatch(
        vd,
        VSL_handler_f(_vsl_handler),
        None
    )


def parse_cli_vsl_args(args):
    """
    Given a list of args, those args will be parsed
    into a list of (arg, value) tuples suitable for
    passing to varnishlog.  These are not checked to
    see if they are valid VSL args, they are only
    transformed into a list of tuples.
    """
    # Guess at parsing CLI args into a list of VSL arg tuples.
    # This is a stupid for/while loop.  Is there a slicker python way?
    vsl_args = []
    i = 0
    while i < len(args):
        # Remove any '-' from this arg.
        arg = args[i].translate(None, '-')
        # If this is the end, or if the next arg has a '-',
        # assume this is a switch that does not take a parameter.
        if i == len(args) - 1 or '-' in args[i + 1]:
            arg_tuple = (arg, '')
        # Else this arg takes a parameter.
        else:
            arg_tuple = (arg, args[i + 1])
            i += 1
        i += 1
        # The key in the VSL arg tuple must be a single character.
        assert len(arg_tuple[0]) == 1
        vsl_args.append(arg_tuple)

    return vsl_args


def print_tags_callback(transaction_id, tag, value, remote_party):
    """
    Prints the entry in a simliar format as the varnishlog C utility.
    """
    if not remote_party:
        remote_party = '-'
    else:
        remote_party = remote_party[0]

    print("%s %s %s %s" % (
        str(transaction_id).rjust(5),
        tag.ljust(12),
        remote_party,
        value
    ))


if __name__ == '__main__':
    varnishlog(
        parse_cli_vsl_args(sys.argv[1:]),
        print_tags_callback
    )


# ##### Tests ######
# To run:
#   python -m unittest varnishlog
#
# This requires that varnishlog.test.data is present
# in the current directory.  It contains 100 entries
# spread across 6 transactions.  It was collected from
# a real text varnish server using the varnishlog utility.
#
def save_entries_callback(entries, xid, tag, value, remote_party):
    """
    Saves records based on transaction_id in a global
    entries dict.
    """
    # print_tags_callback(tag, value, xid, remote_party)
    if xid not in entries:
        entries[xid] = {'remote_party': remote_party}
    if tag not in entries[xid]:
        entries[xid][tag] = []

    entries[xid][tag].append(value)


class TestVarnishlog(unittest.TestCase):
    varnishlog_test_data_file = 'varnishlog.test.data'

    def test_varnishlog(self):
        entries = {}
        callback = functools.partial(save_entries_callback, entries)

        # Test on 100 records from varnishlog.test.data file
        vsl_args = [('r', self.varnishlog_test_data_file)]
        varnishlog(vsl_args, callback)

        # 6 transactions in this varnishlog.test.data file.
        self.assertEqual(len(entries.keys()), 6)
        self.assertEqual(len(entries[410L]['TxHeader']), 8)
        self.assertEqual(entries[410L]['remote_party'], 'client')

        self.assertEqual(entries[163L]['remote_party'], None)
        self.assertEqual(entries[286L]['Length'][0], '11771')

        self.assertEqual(entries[190L]['RxStatus'][0], '200')

    def test_varnishlog_include_tag(self):
        entries = {}
        callback = functools.partial(save_entries_callback, entries)

        # Test on 100 records from varnishlog.test.data file
        vsl_args = [
            ('r', self.varnishlog_test_data_file),
            ('i', 'TxStatus')
        ]
        varnishlog(vsl_args, callback)

        # Two transactions with TxStatus in this varnishlog.test.data file
        self.assertEqual(len(entries.keys()), 2)
        self.assertEqual(entries[286L]['remote_party'], None)
        self.assertEqual(entries[410L]['remote_party'], 'client')
