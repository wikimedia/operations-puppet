#!/usr/bin/python3
# SPDX-License-Identifier: Apache-2.0

"""
Get the status of a Dell PERC RAID controller

Execute and parse the perccli commands in order to print a summary of the RAID
status.
"""

import json
import os
import subprocess
import sys


from typing import Tuple

# Nagios exit codes for easier reference
NAGIOS_OK = 0
NAGIOS_WARN = 1
NAGIOS_CRIT = 2
NAGIOS_UNKN = 3


def run_perccli_command(args) -> dict:
    """Wrapper for the perccli64 tool"""
    cmd = ['/usr/bin/perccli64', args]

    # Capture stdout from command and enable check.
    # Check will cause a CalledProcessError if perccli64 returns with
    # an non-zero exit code. Exception is handled in main.
    perc_data = subprocess.run(cmd, capture_output=True, check=True)
    return json.loads(perc_data.stdout)


def list_controllers() -> list[int]:
    """IDs of the installed controllers"""
    command_args = 'show J'
    data = run_perccli_command(command_args)

    overviews_list = [controller['Response Data']['System Overview']
                      for controller in data['Controllers']]
    overviews = []
    for overview in overviews_list:
        overviews.extend(overview)
    controller_ids = [overview['Ctl'] for overview in overviews]

    return controller_ids


def get_perccli_data(controller_ids) -> Tuple[bool, str, dict]:
    """Get data on disks, enclosure and battery status from the PERCCLI tool, for
    each installed controller.
    """

    controllers = ','.join([str(controller_id) for controller_id in controller_ids])

    # Appending J to any perccli command will return JSON formatet output
    command_args = f'/c{controllers} show all J'
    data = run_perccli_command(command_args)

    # If the controller request does not return "Success", we want to abort
    # any other processing.
    controller_communication_errors = [controller
                                       for controller in data['Controllers']
                                       if controller['Command Status']['Status'] != 'Success']

    if controller_communication_errors:
        # There might be multiple errors, if there are more then one RAID controller,
        # but assume the first error.
        controller = controller_communication_errors[0]
        return NAGIOS_UNKN, f'communication {len(controller_communication_errors)}\
                {controller["Command Status"]["Status"]}', data['Controllers']

    # The PERCCLI tool always returns an array of controllers, even if we
    # specifically requested just the one. Extract the response data from
    # the array to make things easier to work with.
    return NAGIOS_OK, 'communication 0 OK', data['Controllers']


def lookup_by_key(key, data) -> list:
    """Find all devices by key, from any controller.
    Response data may contain data from one or more
    controllers, but for alerting all devices are considered,
    regardless of controller ID.
    """

    # Find response data for each controller.
    controller_data = [controller['Response Data'] for controller in data if
                       'Response Data' in controller]

    # Find device data, by key, for each controller. Will yield a list of
    # devices per controller.
    elements_per_controller = [controller[key] for controller in controller_data]

    # If the elements in the list are not lists, do not attempt to merge.
    if len(elements_per_controller) > 0 and not isinstance(elements_per_controller[0], list):
        return elements_per_controller

    # Merge all device lists into a single list. These are just dicts in lists,
    # so we don't need to worry about duplication.
    devices = []
    for element in elements_per_controller:
        devices.extend(element)
    return devices


def general_state(data) -> Tuple[int, str]:
    """Get overall state from the RAID controller"""
    status_list = lookup_by_key('Status', data)
    errors = [status for status in status_list if status['Controller Status'] != 'Optimal']
    status = 'OK' if not errors else errors[0]['Controller Status']
    exit_code = 0 if not errors else NAGIOS_WARN
    message = f'controller: {len(errors)} {status}'
    return exit_code, message


def physical_device_status(data) -> Tuple[int, str]:
    """Get all physical devices not currently marked as 'online'"""
    devices = lookup_by_key('PD LIST', data)
    errors = [device for device in devices if device['State'] != 'Onln']
    status = 'OK' if not errors else errors[0]['State']
    exit_code = 0 if not errors else NAGIOS_WARN
    message = f'physical_disk: {len(errors)} {status}'
    return exit_code, message


def virtual_device_status(data) -> Tuple[int, str]:
    """Check if a virtual device has the state: Optimal"""
    devices = lookup_by_key('VD LIST', data)
    errors = [device for device in devices if device['State'] != 'Optl']
    status = 'OK' if not errors else errors[0]['State']
    exit_code = 0 if not errors else NAGIOS_CRIT
    message = f'virtual_disk: {len(errors)} {status}'
    return exit_code, message


def bbu_status(data) -> Tuple[int, str]:
    """State of the RAID controllers backup battery unit"""
    devices = lookup_by_key('BBU_Info', data)
    errors = [device for device in devices if device['State'] != 'Optimal']
    status = 'OK' if not errors else errors[0]['State']
    exit_code = 0 if not errors else NAGIOS_WARN
    message = f'bbu: {len(errors)} {status}'

    return exit_code, message


def enclosure_state(data) -> Tuple[bool, str]:
    """Check enclosure state, OK meaning no errors"""
    devices = lookup_by_key('Enclosure LIST', data)
    errors = [device for device in devices if device['State'] != 'OK']
    status = 'OK' if not errors else errors[0]['State']
    exit_code = 0 if not errors else NAGIOS_CRIT
    message = f'enclosure: {len(errors)} {status}'
    return exit_code, message


def parser_controller_data(controller_ids) -> Tuple[int, str]:
    """Parse data from returned by the perccli64 tools"""
    messages = []

    # Communication status, as well as data.
    c_state, c_msg, data = get_perccli_data(controller_ids)
    messages.append(c_msg)

    # General RAID controller state.
    g_state, g_msg = general_state(data)
    messages.append(g_msg)

    # Physical devices
    p_state, p_msg = physical_device_status(data)
    messages.append(p_msg)

    # Virtual devices
    v_state, v_msg = virtual_device_status(data)
    messages.append(v_msg)

    # Backup battery unit
    b_state, b_msg = bbu_status(data)
    messages.append(b_msg)

    # Enclosures
    e_state, e_msg = enclosure_state(data)
    messages.append(e_msg)

    return max(c_state, g_state, p_state, v_state, b_state, e_state), ' | '.join(messages)


def check_permissions():
    """Running the PERCCLI tool without root permissions will work, but
    return no data, as if no controllers are installed.
    """
    if os.getuid() != 0:
        print('Must be run as root')
        sys.exit(NAGIOS_UNKN)


if __name__ == '__main__':
    check_permissions()
    try:
        available_controllers = list_controllers()
        nagios_exit_code, nagios_message = parser_controller_data(available_controllers)
        print(nagios_message)
        sys.exit(nagios_exit_code)
    except subprocess.CalledProcessError as e:
        print(f"perccli64 command failed {e}")
    except Exception as e:
        print(f"Failed to execute {sys.argv}: {e.__class__.__name__} {e}")
        sys.exit(NAGIOS_UNKN)
