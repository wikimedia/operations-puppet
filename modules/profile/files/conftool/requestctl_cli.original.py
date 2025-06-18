#! /usr/bin/env python3
# Copyright (C) 2025 Wikimedia Foundation
# This file is part of HIDDENPARMA, and is released under the Apache License, Version 2.0.
# See COPYRIGHT for details.
# New version of the requestctl CLI tool that connects to the hiddenparma API.
# It does not import anything from the hiddenparma package on purpose, as it needs to be
# able to run anywhere without the hiddenparma package installed.
import logging
import os
import sys

from argparse import ArgumentParser, Namespace
from pathlib import Path
from typing import Any

import json
import yaml
import requests
from requests.exceptions import RequestException, HTTPError

is_development = os.getenv("REQUESTCTL_DEVELOPMENT", "0") == "1"


def get_api_token() -> str:
    """Get the API token from the environment or a file."""

    if is_development:
        return "development"
    api_token = os.getenv("REQUESTCTL_API_TOKEN")
    if not api_token:
        api_token_file = Path("~/.requestctl").expanduser()
        if api_token_file.exists():
            api_token = api_token_file.read_text().strip()
        else:
            raise ValueError("API token not found in environment or file.")
    return api_token


logger = logging.getLogger("requestctl")
API_TOKEN = get_api_token()
default_base_url = "https://requestctl.wikimedia.org"
REQUESTCTL_BASE_URL = os.getenv("REQUESTCTL_BASE_URL", default_base_url)
if is_development and REQUESTCTL_BASE_URL == default_base_url:
    # If we're in development mode, we use a local instance of requestctl.
    REQUESTCTL_BASE_URL = "http://localhost:8000"
UA = os.environ.get("REQUESTCTL_USER_AGENT", "requestctl-cli/1.0")
API_HEADERS = {"x-cheese-bearer": API_TOKEN, "User-Agent": UA}


def api_call(url, method="GET", data=None):
    """Make an API call to the requestctl backend."""
    url = f"{REQUESTCTL_BASE_URL}{url}"
    timeout = 60.0 if method == "GET" else None
    try:
        response = requests.request(method, url, json=data, headers=API_HEADERS, timeout=timeout)
        response.raise_for_status()
        return response.json()
    except HTTPError as e:
        # We want to raise client-related errors (4xx) as is, but handle server errors (5xx) differently.
        if e.response.status_code >= 400 and e.response.status_code < 500:
            raise
        else:
            raise ValueError(f"HTTP Error {e.response.status_code}: {e.response.text}")
    except RequestException as e:
        raise ValueError(f"API call failed: {e}")


def strictly_positive_int(value: Any) -> int:
    """Check if the value is a strictly positive integer."""
    try:
        ivalue = int(value)
        if ivalue <= 0:
            raise ValueError
    except ValueError:
        raise ValueError(f"{value} is not a strictly positive integer")
    return ivalue


# Load the schema from the API
schema_data = api_call("/api/conftool-schema")
ALL_ENTITIES = schema_data.get("schema", {}).keys()
ACTION_ENTITIES = schema_data.get("action_entities", [])
SYNC_ENTITIES = schema_data.get("sync_entities", [])

SCOPE_TO_ENTITY = {
    "varnish": ["action"],
    "haproxy": ["haproxy_action"],
}


def parse_args(args) -> Namespace:
    """Parse command-line arguments."""
    parser = ArgumentParser(
        "requestctl",
        description="Tool to control/ratelimit/ban web requests dynamically",
    )
    parser.add_argument("--config", "-c", help="Configuration file", default="/etc/conftool/config.yaml")
    parser.add_argument("--debug", action="store_true")
    command = parser.add_subparsers(help="Command to execute", dest="command")
    command.required = True
    # Apply command. Modifies or creates an object in the datastore
    # Example: requesctl apply action cache-text/block_cloud -f action.yaml
    apply = command.add_parser("apply", help="Apply an object definition to the datastore.")
    apply.add_argument("object_type", help="What object type to apply", choices=SYNC_ENTITIES)
    apply.add_argument(
        "object_path",
        help="The full name of the object, including tags, e.g. cache-text/block_cloud",
    )
    apply.add_argument("-f", "--file", help="The relative path of file to read the object from", required=True)
    apply.add_argument("--interactive", "-i", help="Interactively apply objects if needed.", action="store_true")
    # Delete command. Deletes an object from the datastore
    # Example: requestctl delete action cache-text/block_cloud
    delete = command.add_parser("delete", help="Delete an object from the datastore.")
    delete.add_argument("object_type", help="What object type to delete", choices=SYNC_ENTITIES)
    delete.add_argument(
        "object_path",
        help="The full name of the object, including tags, e.g. cache-text/block_cloud",
    )
    delete.add_argument("--interactive", "-i", help="Interactively delete objects if needed.", action="store_true")
    # Load command
    # Loads multiple objects from files in the format of requestctl dump's output
    # into the datastore. Can be used to load a single file or a directory of files,
    # with the --tree flag. In that case, it will expect files to be organized in a filesyste
    # tree structure, with the object type as the first directory, and the object tags and names
    # below that, so the same format as the git tree created by conftool2git.
    # Example: requestctl load -f /path/to/dump.yaml
    # Example: requestctl load --tree -f /path/to/dumps/dir
    load = command.add_parser("load", help="Load objects from a dump file into the datastore.")
    load.add_argument(
        "--interactive",
        "-i",
        help="Interactively sync objects if needed.",
        action="store_true",
    )
    load.add_argument(
        "--reset",
        "-r",
        help="Delete all non-derived objects before loading. DANGER: This action is irreversible.",
        action="store_true",
    ),
    file_or_tree = load.add_mutually_exclusive_group(required=True)
    file_or_tree.add_argument("-f", "--file", help="The file to load objects from")
    file_or_tree.add_argument("-t", "--tree", help="Load objects from a directory tree")

    # Dump command. Dumps the datastore to a file that can be used with load.
    dump = command.add_parser(
        "dump",
        help="Dumps the content of the datastore to a format that can be used by load.",
    )
    dump.add_argument("-f", "--file", help="The file to write the dump to", required=True)

    # Enable command. Enables a request action.
    enable = command.add_parser("enable", help="Turns on a specific action")
    enable.add_argument(
        "--scope",
        "-s",
        help="What system to search the action for",
        choices=SCOPE_TO_ENTITY.keys(),
        default="varnish",
    )
    enable.add_argument("action", help="Action to enable")
    # Disable command. Disables a request action
    disable = command.add_parser("disable", help="Turns off a specific action")
    disable.add_argument(
        "--scope",
        "-s",
        help="What object type to disable",
        choices=SCOPE_TO_ENTITY.keys(),
        default="varnish",
    )
    disable.add_argument("action", help="Action to enable")
    # Commit command. Actually compiles the enabled actions to VCL.
    commit = command.add_parser("commit", help="Actually write your changes to the edges.")
    commit.add_argument(
        "--batch",
        "-b",
        help="Does not ask for confirmation before committing",
        action="store_true",
    )
    # Get command
    # Gets either all or one specific object from the datastore, outputs in various formats
    # Examples:
    # requestctl get action
    # requestctl get action cache-text/block_cloud
    # requestctl get action cache-text/block_cloud -o yaml
    get = command.add_parser("get", help="Get an object")
    get.add_argument("object_type", help="What objects to get", choices=ALL_ENTITIES)
    get.add_argument("object_path", help="The full name of the object", nargs="?", default="")
    get.add_argument(
        "-o",
        "--output",
        help="Choose the format for output: json, yaml. ",
        choices=["json", "yaml"],
        default="yaml",
    )
    # Log command. Outputs a typical varnishncsa command to log the selected action
    log = command.add_parser("log", help="Get the varnishncsa to log requests matching an object.")
    log.add_argument(
        "object_path",
        help="The full name of the object",
    )
    # vcl command. Outputs the VCL for the selected action.
    vcl = command.add_parser("vcl", help="Get the varnish VCL that will be generated by this action.")
    vcl.add_argument(
        "object_path",
        help="The full name of the object",
    )
    # haproxycfg command. Outputs the haproxy configuration for the selected action.
    haproxycfg = command.add_parser(
        "haproxycfg",
        help="Get the haproxy configuration that will be generated by this haproxy_action.",
    )
    haproxycfg.add_argument(
        "object_path",
        help="The full name of the object",
    )
    # find command. Returns the actions that include a specific pattern/ipblock
    find = command.add_parser("find", help="Find which actions include a specific pattern/ipblock")
    # Scope is none by default, as we might want to search both varnish and haproxy actions.
    find.add_argument(
        "--scope",
        "-s",
        help="What system to search the action for",
        choices=SCOPE_TO_ENTITY.keys(),
    )
    find.add_argument(
        "search_string",
        help="The string to search in the expression. Must be in the format <scope>/<name>."
        "No regex matching or partial string match is performed.",
    )
    # find-ip command. Returns all the ipblocks and IP belongs to, if any
    find_ip = command.add_parser(
        "find-ip",
        help="Find if an IP is part of any CIDR of any ipblock definitions on disk.",
    )
    find_ip.add_argument(
        "ip",
        help="The IP address to search for.",
    )

    return parser.parse_args(args)


def apply(parsed_args: Namespace):
    """Apply an object definition from a yaml file to the datastore."""
    p = Path(parsed_args.file)
    if not p.exists() or not p.is_file():
        raise FileNotFoundError(f"File {parsed_args.file} does not exist.")

    payload = yaml.safe_load(p.read_text())
    if parsed_args.object_type in ACTION_ENTITIES and "enabled" in payload:
        # If the object is an action, we need to remove the enabled property from the payload,
        del payload["enabled"]

    request_url = f"/api/{parsed_args.object_type}/{parsed_args.object_path}"
    # first check if the object already exists
    try:
        # If the object already exists, we will update it
        existing_object = api_call(request_url)
        method = "PUT"
        # We need to fill in all properties that are not in the payload,
        # as the API will not allow us to update only a subset of properties.
        for key, value in existing_object.items():
            if key not in payload:
                payload[key] = value
    except HTTPError as e:
        if e.response.status_code == 404:
            # If the object does not exist, we will create it
            existing_object = None
            method = "POST"
        else:
            raise ValueError(f"Error applying object: {e.response.status_code} - {e.response.text}")
    if parsed_args.interactive:
        if existing_object is not None:
            print(f"{parsed_args.object_type} {parsed_args.object_path} already exists. Current definition:")
            print("==")
            print(yaml.dump(existing_object, indent=2))
            print("New definition:")
            verb = "Update"
        else:
            print(f"Applying new {parsed_args.object_type} {parsed_args.object_path} from {p}:")
            verb = "Create"
        print("==")
        print(yaml.dump(payload, indent=2))
        confirm = input(f"{verb} {parsed_args.object_type} {parsed_args.object_path}? (y/N): ").strip().lower()
        if confirm != "y":
            print("Aborting apply.")
            return
    try:
        api_call(request_url, method=method, data=payload)
    except HTTPError as e:
        if e.response.status_code == 400:
            raise ValueError(f"Bad request: {e.response.text}")
        elif e.response.status_code >= 500:
            raise
        else:
            raise ValueError(f"Error applying object: {e.response.status_code} - {e.response.text}")


def get(parsed_args: Namespace):
    """Get an object from the datastore."""
    if not parsed_args.object_path:
        all_object_paths = api_call(f"/api/{parsed_args.object_type}")
    else:
        # Check we do have a valid object path
        if "/" not in parsed_args.object_path:
            raise ValueError(
                f"Invalid object path: {parsed_args.object_path}. It should be in the format <scope>/<name>."
            )
        all_object_paths = [parsed_args.object_path]
    out = {}
    for path in all_object_paths:
        request_url = f"/api/{parsed_args.object_type}/{path}"
        try:
            response = api_call(request_url)
            out[path] = response
        except HTTPError as e:
            if e.response.status_code == 404:
                logger.error(f"Object {path} not found.")
            else:
                raise ValueError(f"Error getting object: {e.response.status_code} - {e.response.text}")

    if parsed_args.object_path:
        out = out.get(parsed_args.object_path, {})
    if parsed_args.output == "json":
        print(json.dumps(out, indent=2))
    elif parsed_args.output == "yaml":
        print(yaml.dump(out, indent=2))


def load(parsed_args: Namespace):
    """Load objects from a file or directory tree into the datastore."""
    if parsed_args.file:
        p = Path(parsed_args.file)
        if not p.exists() or not p.is_file():
            raise FileNotFoundError(f"File {parsed_args.file} does not exist.")
    elif parsed_args.tree:
        p = Path(parsed_args.tree)
        if not p.exists() or not p.is_dir():
            raise FileNotFoundError(f"Directory {parsed_args.tree} does not exist.")

    sync_first = set(SYNC_ENTITIES) - set(ACTION_ENTITIES)

    if parsed_args.reset:
        if sys.stdout.isatty():
            print("WARNING: This will delete all non-derived objects.")
            print("ONLY use this option if you're reloading a full dump " "and you know what you are doing.")

            confirm = input("Do you want to proceed? (y/N): ").strip().lower()
            if confirm != "y":
                print("Aborting reset.")
                sys.exit(1)
        # Reset the actions first, as they might depend on the other objects
        for entity in ACTION_ENTITIES:
            logger.info(f"Resetting {entity} objects...")
            try:
                _reset(entity)
                logger.info(f"Removed {entity} objects successfully.")
            except ValueError as e:
                logger.error(f"Error resetting {entity}: {e}")

        for entity in sync_first:
            logger.info(f"Resetting {entity} objects...")
            try:
                _reset(entity)
                logger.info(f"Removed {entity} objects successfully.")
            except ValueError as e:
                logger.error(f"Error resetting {entity}: {e}")

    if parsed_args.file:
        with open(p, "r") as f:
            payload = list(yaml.safe_load_all(f))
    elif parsed_args.tree:
        payload = []
        for file in p.rglob("*.yaml"):
            if not file.is_file():
                continue
            scope = file.parent.name
            entity = file.parent.parent.name
            with open(file, "r") as f:
                data = yaml.safe_load(f)
                metadata = {"type": entity, "path": f"{scope}/{file.stem}"}
                payload.append({"metadata": metadata, "data": data})
    else:
        raise ValueError("Either --file or --tree must be specified.")
    resp = api_call("/api/load", method="POST", data=payload)
    if resp.get("status") == "ok":
        print(f"Loaded {len(payload)} objects successfully.")
    else:
        print("Error loading objects:")
        for error in resp.get("errors", []):
            print(f"- {error}")
        raise ValueError("Error loading objects")


def _reset(object_type: str):
    """Reset the datastore by deleting all objects of the specified type."""
    request_url = f"/api/{object_type}"
    try:
        obj = None
        existing_objects = api_call(request_url)
        for obj in existing_objects:
            api_call(f"{request_url}/{obj}", method="DELETE")
    except HTTPError as e:
        raise ValueError(f"Error resetting {object_type}/{obj}: {e.response.status_code} - {e.response.text}")


def delete(parsed_args: Namespace):
    """Delete an object from the datastore."""
    request_url = f"/api/{parsed_args.object_type}/{parsed_args.object_path}"
    if parsed_args.interactive:
        confirm = (
            input(f"Are you sure you want to delete {parsed_args.object_type} {parsed_args.object_path}? (y/N): ")
            .strip()
            .lower()
        )
        if confirm != "y":
            print("Aborting delete.")
            return
    try:
        api_call(request_url, method="DELETE")
        print(f"Deleted {parsed_args.object_type} {parsed_args.object_path} successfully.")
    except HTTPError as e:
        if e.response.status_code == 404:
            logger.error(f"Object {parsed_args.object_type} {parsed_args.object_path} not found.")
        else:
            raise ValueError(f"Error deleting object: {e.response.status_code} - {e.response.text}")


def enable(parsed_args: Namespace, enable: bool):
    """Enable a request action."""
    object_type = SCOPE_TO_ENTITY.get(parsed_args.scope, ["action"])[0]
    request_url = f"/api/{object_type}/{parsed_args.action}"
    # We can only enable actions that are defined in the datastore, so we assume
    # that this is an update operation.
    try:
        obj = api_call(request_url)
        if obj.get("enabled") == enable:
            print(f"{parsed_args.action} is already {'enabled' if enable else 'disabled'}.")
            return
        obj["enabled"] = enable
        api_call(request_url, method="PUT", data=obj)
        print(f"{'Enabled' if enable else 'Disabled'} {parsed_args.action} on {parsed_args.scope} successfully.")
    except HTTPError as e:
        if e.response.status_code == 404:
            raise ValueError(f"Action {parsed_args.action} not found in scope {parsed_args.scope}.")
        else:
            raise ValueError(f"Error enabling action: {e.response.status_code} - {e.response.text}")


def dump(parsed_args: Namespace):
    """Dump the datastore to a file."""
    everything = []
    for object_type in SYNC_ENTITIES:
        request_url = f"/api/{object_type}"
        try:
            objects = api_call(request_url)
        except HTTPError as e:
            if e.response.status_code == 404:
                logger.info(f"No objects of type {object_type} found.")
                continue
            else:
                raise ValueError(f"Error dumping objects: {e.response.status_code} - {e.response.text}")
        for obj in objects:
            # Add metadata to each object
            metadata = {"type": object_type, "path": obj}
            try:
                data = api_call(f"{request_url}/{obj}")
                everything.append({"metadata": metadata, "data": data})
            except HTTPError as e:
                if e.response.status_code == 404:
                    logger.error(f"{object_type.capitalize()} not found at {request_url}/{obj}.")
                else:
                    raise ValueError(f"Error dumping object: {e.response.status_code} - {e.response.text}")
    with open(parsed_args.file, "w") as f:
        yaml.dump_all(everything, f, sort_keys=False)


def find(parsed_args: Namespace):
    """Find actions that match a specific pattern or ipblock."""
    search_string = parsed_args.search_string
    if "/" not in search_string:
        raise ValueError("Search string must be in the format <scope>/<name>.")
    if parsed_args.scope:
        object_type = SCOPE_TO_ENTITY[parsed_args.scope][0]
    else:
        # If no scope is specified, we search all action entities
        object_type = "all"
    try:
        response = api_call(f"/api/match_expression?q={search_string}&scope={object_type}")
    except HTTPError as e:
        if e.response.status_code == 404:
            print("No entries found.")
            return
        else:
            raise ValueError(f"Error finding actions: {e.response.status_code} - {e.response.text}")
    print(f"Found {len(response.get('matches', []))} actions matching {search_string}:")
    for result in response.get("matches", []):
        print(f"- {result}")


def find_ip(parsed_args: Namespace):
    """Find if an IP is part of any CIDR of any ipblock definitions."""
    ip_address = parsed_args.ip
    if not ip_address:
        raise ValueError("IP address must be specified.")
    try:
        response = api_call("/api/match_ip?ip=" + ip_address)
    except HTTPError as e:
        if e.response.status_code == 404:
            response = {}
        else:
            raise ValueError(f"Error finding IP: {e.response.status_code} - {e.response.text}")
    matching = response.get("matches", [])
    if len(matching) > 0:
        print(f"IP {ip_address} is part of the following ipblocks:")
        for ipblock in matching:
            print(f"- {ipblock}")
        return
    else:
        print(f"IP {ip_address} is not part of any ipblock in the datastore.")


def commit(parsed_args: Namespace):
    """Show differences in the DSLs, ask confirmation, and commit the changes."""

    def show_diffs(data):
        """Format the diffs for display."""
        diffs = []
        for cluster, scope in data.items():
            for scope_name, diff in scope.items():
                if diff[1]:
                    # Trick until we need to support python 3.11 and f-strings can't contain newlines
                    diffs.append("\n".join([f"== {cluster}/{scope_name} ==", diff[1].replace("\n\n", "\n"), "=="]))
        return "\n".join(diffs)

    # If batch mode is enabled, we skip the confirmation step
    response = api_call("/api/commit")
    if not response.get("vcl") and not response.get("haproxy"):
        print("No changes to commit.")
        return
    if not parsed_args.batch:
        print("The following changes will be made:")
        print("Varnish VCL changes:")
        if response.get("vcl"):
            diffs = show_diffs(response.get("vcl"))
            if diffs:
                print(diffs)
            else:
                print("No changes in Varnish VCL.")
        else:
            print("No changes in Varnish VCL.")
        print("==")
        print("HAProxy DSL changes:")
        if response.get("haproxy"):
            diffs = show_diffs(response.get("haproxy"))
            if diffs:
                print(diffs)
            else:
                print("No changes in HAProxy DSL.")
        else:
            print("No changes in HAProxy DSL.")

        confirm = input("Do you want to proceed with the commit? (y/N): ").strip().lower()
        if confirm != "y":
            print("Aborting commit.")
            return
    try:
        response = api_call("/api/commit", method="POST", data=response)
        if response.get("status", "nok") == "ok":
            print("Changes committed successfully.")
    except HTTPError as e:
        raise ValueError(f"Error committing changes: {e.response.status_code} - {e.response.text}")


def vsl(parsed_args: Namespace):
    """Get the VSL for a specific action."""
    request_url = f"/api/action/{parsed_args.object_path}/vsl"
    try:
        response = api_call(request_url)
        print(response.get("vsl", "No VSL found for this action."))
    except HTTPError as e:
        if e.response.status_code == 404:
            print(f"VSL for {parsed_args.object_path} not found.")
        else:
            raise ValueError(f"Error getting VSL: {e.response.status_code} - {e.response.text}")


def vcl(parsed_args: Namespace):
    """Get the VCL for a specific action."""
    request_url = f"/api/action/{parsed_args.object_path}/dsl"
    try:
        response = api_call(request_url)
        print(response.get("dsl", "No VCL found for this action."))
    except HTTPError as e:
        if e.response.status_code == 404:
            print(f"VCL for {parsed_args.object_path} not found.")
        else:
            raise ValueError(f"Error getting VCL: {e.response.status_code} - {e.response.text}")


def haproxycfg(parsed_args: Namespace):
    """Get the HAProxy configuration for a specific action."""
    request_url = f"/api/haproxy_action/{parsed_args.object_path}/dsl"
    try:
        response = api_call(request_url)
        print(response.get("dsl", "No HAProxy configuration found for this action."))
    except HTTPError as e:
        if e.response.status_code == 404:
            print(f"HAProxy configuration for {parsed_args.object_path} not found.")
        else:
            raise ValueError(f"Error getting HAProxy configuration: {e.response.status_code} - {e.response.text}")


def main(args=None):
    """Main function to run the requestctl CLI."""
    if args is None:
        args = sys.argv[1:]

    parsed_args = parse_args(args)

    # Set up logging
    logging.basicConfig(level=logging.DEBUG if parsed_args.debug else logging.INFO)
    logger.setLevel(logging.DEBUG if parsed_args.debug else logging.INFO)
    cmd = parsed_args.command
    if cmd == "get":
        return get(parsed_args)
    elif cmd == "apply":
        return apply(parsed_args)
    elif cmd == "load":
        return load(parsed_args)
    elif cmd == "delete":
        return delete(parsed_args)
    elif cmd == "dump":
        return dump(parsed_args)
    elif cmd == "enable":
        return enable(parsed_args, True)
    elif cmd == "disable":
        return enable(parsed_args, False)
    elif cmd == "find":
        return find(parsed_args)
    elif cmd == "find-ip":
        return find_ip(parsed_args)
    elif cmd == "commit":
        return commit(parsed_args)
    elif cmd == "vcl":
        return vcl(parsed_args)
    elif cmd == "log":
        return vsl(parsed_args)
    elif cmd == "haproxycfg":
        return haproxycfg(parsed_args)
    else:
        raise ValueError(f"{cmd} is not a valid option.")


if __name__ == "__main__":
    try:
        main()
    except Exception as e:
        logger.error(f"Error occurred: {e}")
        sys.exit(1)
