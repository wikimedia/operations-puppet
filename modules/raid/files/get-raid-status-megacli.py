#!/usr/bin/python
"""
Get the status of a MegaRAID RAID

Execute and parse megacli commands in order to print a summary of the RAID
status. By default only components in non-optimal status are shown.
"""

import argparse
import subprocess
import zlib

ADAPTER_LINE_STARTSWITH = 'Adapter #'
EXIT_LINE_STARTSWITH = 'Exit Code:'

# Hierarchically ordered contexts
ORDERED_CONTEXTS = ('raw_disk', 'physical_drive', 'span', 'virtual_drive',
                    'adapter')

# Rules on how to interpret the megacli output and how to do the summary
CONTEXTS = {
    'adapter': {
        'parent': None,
        'include_childs': False,
        'optimal_values': {},
        'print_keys': ('name', ),
    },
    'virtual_drive': {
        'parent': 'adapter',
        'include_childs': False,
        'optimal_values': {'State': 'Optimal'},
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
        'optimal_values': {
            'Media Error Count': '0',
            'Other Error Count': '0',
            'Predictive Failure Count': '0',
            'Last Predictive Failure Event Seq Number': '0',
        },
        'print_keys': (
            'PD',
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
        'optimal_values': {'Firmware state': 'Online, Spun Up'},
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
}


class RaidStatus():
    """Representation of a RAID status with all it's components"""

    def __init__(self):
        """Class constructor"""
        self.adapters = []  # There can be multiple adapters
        self.current_context = None  # Pointer to the current context

        # Pointers to the current open contexts
        self.adapter = None
        self.virtual_drive = None
        self.span = None
        self.physical_drive = None
        self.raw_disk = None

    def add_block(self, context, key, value):
        """ Initialize a new block and move it's related pointer

            Arguments:
            context -- the context name of the new block
            key     -- the key to be added to the new block
            value   -- the value to be added to the new block for the given key
        """

        self.consolidate(context)
        setattr(self, context, {
            'context': context,
            'optimal': True,
            'childs': [],
        })

        self.current_context = getattr(self, context)
        self.set_property(key, value)

    def set_property(self, key, value):
        """ Set a property in the current context

            Also detect if it's in a non-optimal state and mark as non-optimal
            all the blocks in the parent chain too

            Arguments:
            key     -- the key to be added to the new block
            value   -- the value to be added to the new block for the given key
        """

        self.current_context[key] = value

        context_name = self.current_context['context']
        optimal_values = CONTEXTS[context_name]['optimal_values']

        if key in optimal_values.keys() and optimal_values[key] != value:
            self.current_context['optimal'] = False
            sep = '====='
            self.current_context[key] = '{}> {} <{}'.format(
                sep, self.current_context[key], sep)

            # Mark as non optimal the whole parent chain
            while True:
                if CONTEXTS[context_name]['parent'] is None:
                    break

                parent = getattr(self, CONTEXTS[context_name]['parent'])
                parent['optimal'] = False
                context_name = parent['context']

    def consolidate(self, final_context='adapter'):
        """ Reset all open contexts adding them to their parent

            Keyword arguments:
            final_context -- the name of the context up to which consolidate
        """

        for context in ORDERED_CONTEXTS:
            block = getattr(self, context)
            parent_context = CONTEXTS[context]['parent']

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
        for key in CONTEXTS[block['context']]['print_keys']:
            try:
                status.append('{}{}: {}'.format(prefix, key, block[key]))
            except:
                pass  # Explicitely ignore missing keys

        status.append('')  # Separate each block

        for child in block['childs']:
            # Skip the child if not needed
            if not get_all and child['optimal']:
                if (block['optimal'] or
                        not CONTEXTS[block['context']]['include_childs']):
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
        '-c', dest='compress', action='store_true',
        help='Compress with zlib the summary to overcome NRPE output limits.')
    parser.add_argument(
        '-a', dest='all', action='store_true',
        help='Include all components in the summary.')

    return parser.parse_args()


def parse_megacli_status(status):
    """ Get the RAID status from the remote host through NRPE

        Arguments:
        status -- a RaidStatus instance
    """

    try:
        command = ['/usr/sbin/megacli', '-LdPdInfo', '-aAll']
        proc = subprocess.Popen(command, stdout=subprocess.PIPE)
    except:
        print('Unable to run: {}'.format(command))

    for line in proc.stdout:
        line = line.strip(' \t\r\n')

        if len(line) == 0:
            continue

        _process_line(line, status)

    proc.wait()


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

    if key in KEY_TO_CONTEXT.keys():
        status.add_block(KEY_TO_CONTEXT[key], key, value)
    else:
        status.set_property(key, value)


if __name__ == '__main__':
    args = parse_args()

    status = RaidStatus()
    parse_megacli_status(status)
    summary = status.get_status(get_all=args.all)

    if args.compress:
        # NRPE doesn't handle NULL bytes, encoding them.
        # Given the specific domain there is no need of a full yEnc encoding
        print(zlib.compress(summary).replace('\x00', '###NULL###'))
    else:
        print(summary)
