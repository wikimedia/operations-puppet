#!/usr/bin/python
"""
Get the status of a MegaRAID RAID

Execute and parse megacli commands in order to print a summary of the RAID
status. By default only components in non-optimal status are shown.
"""

from __future__ import print_function

import argparse
import subprocess
import sys
import zlib

from collections import Counter

ADAPTER_LINE_STARTSWITH = 'Adapter #'
EXIT_LINE_STARTSWITH = 'Exit Code:'

# Hierarchically ordered contexts
ORDERED_LOGICAL_CONTEXTS = (
    'raw_disk', 'physical_drive', 'span', 'virtual_drive', 'adapter')
ORDERED_PHYSICAL_CONTEXTS = ('raw_disk', 'enclosure_slot', 'adapter')

# Rules on how to interpret the megacli output and how to do the summary
LOGICAL_CONTEXTS = {
    'adapter': {
        'parent': None,
        'include_childs': False,
        'optimal_values': {},
        'print_keys': ('name', ),
    },
    'virtual_drive': {
        'parent': 'adapter',
        'include_childs': False,
        'optimal_values': {'State': ['Optimal']},
        'print_keys': (
            'Virtual Drive',
            'RAID Level',
            'State',
            'Number Of Drives',
            'Number Of Drives per span',
            'Number of Spans',
            'Current Cache Policy',
        ),
    },
    'span': {
        'parent': 'virtual_drive',
        'include_childs': False,
        'optimal_values': {},
        'print_keys': ('Span', ),
    },
    'physical_drive': {
        'parent': 'span',
        'include_childs': True,
        'warning': True,
        'optimal_values': {
            'Predictive Failure Count': ['0'],
            'ERROR': [''],
        },
        'print_keys': (
            'PD',
            'ERROR',
            'Enclosure Device ID',
            'Slot Number',
            "Drive's position",
            'Media Error Count',
            'Other Error Count',
            'Predictive Failure Count',
            'Last Predictive Failure Event Seq Number',
        ),
    },
    'raw_disk': {
        'parent': 'physical_drive',
        'include_childs': False,
        'optimal_values': {'Firmware state': ['Online, Spun Up']},
        'print_keys': (
            'Raw Size',
            'Firmware state',
            'Media Type',
            'Drive Temperature',
        ),
    }
}

PHYSICAL_CONTEXTS = {
    'adapter': {
        'parent': None,
        'include_childs': False,
        'optimal_values': {},
        'print_keys': ('name', ),
    },
    'enclosure_slot': {
        'parent': 'adapter',
        'include_childs': True,
        'optimal_values': {
            'Predictive Failure Count': ['0'],
        },
        'print_keys': (
            'Enclosure Device ID',
            'Slot Number',
            'Enclosure position',
            'Device Id',
            'Media Error Count',
            'Other Error Count',
            'Predictive Failure Count',
            'Last Predictive Failure Event Seq Number',
        ),
    },
    'raw_disk': {
        'parent': 'enclosure_slot',
        'include_childs': False,
        'optimal_values': {'Firmware state': ['JBOD', 'Online, Spun Up']},
        'print_keys': (
            'Raw Size',
            'Firmware state',
            'Media Type',
            'Drive Temperature',
        ),
    }
}


# Keys that determines the change of context from one block to the next one
KEY_TO_CONTEXT = {
    'Adapter': 'adapter',
    'Virtual Drive': 'virtual_drive',
    'Span': 'span',
    'PD': 'physical_drive',
    'Raw Size': 'raw_disk',
    'Enclosure Device ID': 'enclosure_slot',
}


class RaidStatus():
    """Representation of a RAID status with all it's components"""

    def __init__(self, physical=False):
        """Class constructor"""
        self.adapters = []  # There can be multiple adapters
        self.current_context = None  # Pointer to the current context

        # Pointers to the current open contexts
        self.adapter = None
        self.virtual_drive = None
        self.span = None
        self.physical_drive = None
        self.raw_disk = None
        self.enclosure_slot = None

        # Initialize counters
        self.counters = Counter()
        self.failed = Counter()

        if physical:
            self.contexts = PHYSICAL_CONTEXTS
            self.ordered_contexts = ORDERED_PHYSICAL_CONTEXTS
        else:
            self.contexts = LOGICAL_CONTEXTS
            self.ordered_contexts = ORDERED_LOGICAL_CONTEXTS

    def add_block(self, context, key, value):
        """ Initialize a new block and move it's related pointer

            Arguments:
            context -- the context name of the new block
            key     -- the key to be added to the new block
            value   -- the value to be added to the new block for the given key
        """
        new_block = {
            'context': context,
            'optimal': True,
            'childs': [],
            'values': {},
        }

        # Before initializing the new context, perform a sanity check of the current one
        if (self.current_context is not None and self.current_context['context'] == 'physical_drive'
                and len(self.current_context['values']) == 1):
            # Only the PD key is present, the drive is broken and megacli fails to read its info.
            self.set_property('ERROR', 'MISSING DRIVE INFO')

        self.consolidate(final_context=context)
        setattr(self, context, new_block)

        self.current_context = getattr(self, context)
        self.set_property(key, value)
        self.counters[context] += 1

    def set_property(self, key, value):
        """ Set a property in the current context

            Also detect if it's in a non-optimal state and mark as non-optimal
            all the blocks in the parent chain too

            Arguments:
            key     -- the key to be added to the new block
            value   -- the value to be added to the new block for the given key
        """

        self.current_context['values'][key] = value

        context_name = self.current_context['context']
        optimal_values = self.contexts[context_name]['optimal_values']

        if key in optimal_values.keys() and value not in optimal_values[key]:
            self.current_context['optimal'] = False
            self.failed[context_name] += 1
            sep = '====='
            self.current_context['values'][key] = '{}> {} <{}'.format(
                sep, self.current_context['values'][key], sep)

            # Mark as non optimal the whole parent chain
            while True:
                if self.contexts[context_name]['parent'] is None:
                    break

                parent = getattr(self, self.contexts[context_name]['parent'])
                parent['optimal'] = False
                context_name = parent['context']

    def consolidate(self, final_context='adapter'):
        """ Reset all open contexts adding them to their parent

            Keyword arguments:
            final_context -- the name of the context up to which consolidate
        """

        for context in self.ordered_contexts:
            block = getattr(self, context)
            parent_context = self.contexts[context]['parent']

            # End of parents chain reached
            if parent_context is None:
                if block is not None and context == 'adapter':
                    self.adapters.append(block)
                break

            parent = getattr(self, parent_context)
            if block is not None:
                parent['childs'].append(block)
                setattr(self, context, None)

            if context == final_context:
                break

    def get_status(self, get_all=False):
        """ Return a string with the summarized RAID status

            Keyword arguments:
            get_all -- if False print only hierarchical chains where there is
                       at least one non-optimal block, all blocks otherwise
        """

        status = []
        message = 'does not include components in optimal state'
        if get_all:
            message = 'includes all components'

        status.append('=== RaidStatus ({})'.format(message))

        for adapter in self.adapters:
            if not get_all and adapter['optimal']:
                continue

            status += self._get_block_status(adapter, get_all=get_all)

        status.append('=== RaidStatus completed')

        return '\n'.join(status)

    def get_nagios_status(self):
        """Return Nagios-compatible status message and exit status code"""
        items = []
        exit_code = 0

        for context in self.ordered_contexts:
            failed = self.failed[context]
            total = self.counters[context]

            if failed == 0:
                items.append('{}: {} OK'.format(context, total))
                continue

            if ('warning' in self.contexts[context] and
                    self.contexts[context]):
                suffix = 'WARN'
                if exit_code < 1:
                    exit_code = 1  # Nagios WARNING
            else:
                suffix = 'CRIT'
                exit_code = 2  # Nagios CRITICAL

            items.append('{}: {}/{} {}'.format(
                context, failed, total, suffix))

        return ' | '.join(items), exit_code

    def _get_block_status(self, block, prefix='', get_all=False):
        """ Return an array of string with the summary of the given block

            Arguments:
            block   -- the block to be printed

            Keyword arguments:
            prefix  -- a prefix to be added before each printed line
            optimal -- if False print only hierarchical chains where there is
                       at least one non-optimal block, all blocks otherwise
        """

        status = []
        for key in self.contexts[block['context']]['print_keys']:
            try:
                status.append('{}{}: {}'.format(prefix, key, block['values'][key]))
            except KeyError:
                pass  # Explicitely ignore missing keys

        status.append('')  # Separate each block

        for child in block['childs']:
            # Skip the child if not needed
            if not get_all and child['optimal']:
                if (block['optimal'] or
                        not self.contexts[block['context']]['include_childs']):
                    continue

            status += self._get_block_status(
                child, prefix=prefix + '\t', get_all=get_all)

        return status


def parse_args():
    """Parse command line arguments"""

    parser = argparse.ArgumentParser(
        description=('Print a summarized status of all non-optimal components '
                     'of all detected MegaRAID controllers'))
    parser.add_argument(
        '-c', '--compress', action='store_true',
        help='Compress with zlib the summary to overcome NRPE output limits.')
    parser.add_argument(
        '-a', '--all', action='store_true',
        help='Include all components in the summary, not only failing ones.')
    parser.add_argument(
        '-n', '--nagios', action='store_true',
        help='Print a Nagios-compatible message and exit status code')

    return parser.parse_args()


def parse_megacli_status(command, status):
    """ Parse the RAID status

        Arguments:
        command -- the command to execute
        status  -- the RaidStatus to use to store the parsed results
    """

    proc = subprocess.Popen(command, stdout=subprocess.PIPE)

    for line in proc.stdout:
        line = line.strip(' \t\r\n')

        if len(line) == 0:
            continue

        _process_line(line, status)

    proc.wait()


def get_megacli_status():
    """Get the RAID status and return a RaidStatus instance"""

    status = RaidStatus()
    command = ['/usr/sbin/megacli', '-LdPdInfo', '-aAll', '-NoLog']
    parse_megacli_status(command, status)

    # If no Virtual drive found, retry with physical ones
    if status.counters['physical_drive'] == 0:
        status = RaidStatus(physical=True)
        command = ['/usr/sbin/megacli', '-PDList', '-aAll', '-NoLog']
        parse_megacli_status(command, status)

    return status


def _process_line(line, status):
    """ Process a RAID status output line and add it to a RaidStatus instance

        Arguments:
        line   -- the line to be processed
        status -- a RaidStatus instance
    """

    if line.startswith(ADAPTER_LINE_STARTSWITH):
        status.add_block('adapter', 'name', line)
        return
    elif line.startswith(EXIT_LINE_STARTSWITH):
        status.consolidate()
        return

    key, value = [el.strip(' \t\r\n') for el in line.split(':', 1)]

    if (key in KEY_TO_CONTEXT.keys() and
            KEY_TO_CONTEXT[key] in status.contexts.keys()):
        status.add_block(KEY_TO_CONTEXT[key], key, value)
    else:
        status.set_property(key, value)


def main(args):
    """Get the RAID status according to command line options"""
    status = get_megacli_status()

    if args.nagios:
        message, exit_code = status.get_nagios_status()
    else:
        message = status.get_status(get_all=args.all)
        exit_code = 0

    if args.compress:
        # NRPE doesn't handle NULL bytes, encoding them.
        # Given the specific domain there is no need of a full yEnc encoding
        print(zlib.compress(message).replace('\x00', '###NULL###'))
    else:
        print(message)

    return exit_code


if __name__ == '__main__':
    try:
        args = parse_args()
        exit_code = main(args)
    except Exception as e:
        print("Failed to execute '{}': {} {}".format(
            ' '.join(sys.argv), e.__class__.__name__, e.message))
        exit_code = 3  # Nagios UNKNOWN

    sys.exit(exit_code)
