#!/usr/bin/python3
"""
generate_check_icinga_contacts.py

Print to stdout the YAML contacts configuration for the Icinga meta-monitoring script.

- Parse the Icinga contactgroups configuration file to find the members of the 'sms' contactgroup.
- Exclude any non-human contact present in the EXCLUDE_CONTACTS list.
- Parse the Icinga contacts configuration file to grab for each contact in the 'sms' contactgroup
  their email, pager and notification hours, converting the notification hours from the Icinga
  format to the Icinga meta-monitoring script format.
- Generate and print to stdout the YAML contacts configuration (emails and pagers) to be used by
  the Icinga meta-monitoring script present in the 'operations/software/external-monitoring'
  repository.
"""
import os
from collections import defaultdict

import yaml


CONFIG_DIR = '/etc/icinga/objects'
EXCLUDE_CONTACTS = ('team-operations',)
# See modules/nagios_common/files/timeperiods.cfg
CHECK_ICINGA_START_END = {
    'none': (None, None),
    '24x7': (0, 23),
    'CET_awake_hours': (7, 22),
    'CEST_awake_hours': (6, 21),
    'EST_awake_hours': (13, 4),
    'EST_awake_early_hours': (12, 3),
    'EDT_awake_hours': (12, 3),
    'EDT_awake_early_hours': (11, 2),
    'PST_awake_hours': (16, 7),
    'PDT_awake_hours': (15, 6),
    'MST_awake_hours': (15, 6),
    'MDT_awake_hours': (14, 5),
    'CST_awake_hours': (14, 3),
}


def parse_icinga_file(filename, unique_key):
    """Parse a generic Icinga configuration file using the unique_key as key in the dictionary.

    It supports the use of partially defined objects (templates) saving them in the
    'objectname_template' key and automatically applying them when used. The final objects under the
    'objectname' key already have the template key/values updated, and potentially overridden, by
    their own key/values.

    Arguments:
        filename (str): the name or path of the configuration file relative to the CONFIG_DIR.
        unique_key (str): the name of the key to use as unique identifier in the parsed dictionary.

    Returns:
        defaultdict: a defaultdict of dictionaries with the following structure:
                {
                    objectname: {
                        unique_key_value: {key: value, ...}
                    }
                }

            for example:

                defaultdict(<class 'dict'>, {
                    'contactgroup': {
                        'admins': {
                            'contactgroup_name': 'admins',
                            'members': 'irc',
                            'alias': 'admins'
                        }
                    }
                }

    """
    with open(os.path.join(CONFIG_DIR, filename)) as f:
        lines = f.readlines()

    objects = defaultdict(dict)
    in_object = False
    for line in lines:
        if line.startswith('define ') and not in_object:
            in_object = True
            object_type = line.split()[1]
            if object_type[-1] == '{':
                object_type = object_type[:-1]
            current_object = {}
        elif line == '}\n' and in_object:
            in_object = False
            if 'use' in current_object:
                new_object = objects[object_type + '_templates'][current_object['use']]
                new_object.update(current_object)
                current_object = new_object

            if unique_key in current_object:
                objects[object_type][current_object[unique_key]] = current_object
            else:
                objects[object_type + '_templates'][current_object['name']] = current_object
        elif in_object:
            parts = line.split()
            current_object[parts[0]] = parts[1]

    return objects


def main():
    """Generate and print the YAML contacts configuration for the Icinga meta-monitoring script."""
    contactgroups = parse_icinga_file('contactgroups.cfg', 'contactgroup_name')
    contacts = parse_icinga_file('contacts.cfg', 'contact_name')

    contact_names = [name for name in contactgroups['contactgroup']['sms']['members'].split(',')
                     if name not in EXCLUDE_CONTACTS]

    check_icinga_config = {'emails': {}, 'pagers': {}}
    for name in contact_names:
        contact = contacts['contact'][name]
        check_icinga_config['emails'][name] = contact['email']
        start, end = CHECK_ICINGA_START_END[contact['service_notification_period']]

        if start is None or end is None:  # Notification disabled
            continue

        if 'address1' in contact:
            check_icinga_config['pagers'][name] = {
                'email': contact['address1'], 'start': start, 'end': end}

    print(yaml.dump(check_icinga_config, default_flow_style=False))


if __name__ == '__main__':
    main()
