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


def local_api_token() -> str:
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
API_TOKEN = local_api_token()
default_base_url = "https://requestctl.wikimedia.org"
REQUESTCTL_BASE_URL = os.getenv("REQUESTCTL_BASE_URL", default_base_url).rstrip("/")
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
EXPRESSION_ENTITIES = schema_data.get("expression_entities", [])
SYNC_ENTITIES = schema_data.get("sync_entities", [])
ENTITIES_SYNC_ORDER = schema_data.get("sync_order", [])

# The set of supported requestctl rule scopes, together with the entity types that define them and
# the specific field that enables them.
# TODO: swfrench - This depends on the schema. Evaluate whether this should be provided by the API.
SCOPES = {
    "varnish": ("action", "enabled"),
    "haproxy": ("haproxy_action", "enabled"),
    "known_client:identify": ("known_client", "identify_enabled"),
    "known_client:deny": ("known_client", "deny_enabled"),
    "ipblock": ("ipblock", "enabled"),
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

    # Enable command.
    # Enables a requestctl rule associated with an action or known-client.
    # Enables ipblock objects to be rendered to haproxy map.
    enable = command.add_parser(
        "enable",
        help="Turns on a specific request rule in an action or known-client. Enables ipblocks to be rendered to haproxy map.",
    )
    enable.add_argument(
        "--scope",
        "-s",
        help="The requestctl rule scope for which to enable the target object",
        choices=SCOPES.keys(),
        default="varnish",
    )
    enable.add_argument("target", help="The target action or known-client to operate on")
    # Disable command.
    # Disables a requestctl rule associated with an action or known-client.
    # Disables ipblock objects from being rendered to haproxy map.
    disable = command.add_parser(
        "disable",
        help="Turns off a specific request rule in an action or known-client. Disables ipblocks from being rendered to haproxy map.",
    )
    disable.add_argument(
        "--scope",
        "-s",
        help="The requestctl rule scope for which to disable the target object",
        choices=SCOPES.keys(),
        default="varnish",
    )
    disable.add_argument("target", help="The target action or known-client to operate on")
    # Commit command. Actually compiles the enabled rules to DSL and stores the result to etcd.
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
        help="Get the haproxy configuration that will be generated by this object (haproxy_action or known_client).",
    )
    haproxycfg.add_argument(
        "--object-type",
        default="haproxy_action",
        choices=["haproxy_action", "known_client"],
        help="The type of the object",
    )
    haproxycfg.add_argument(
        "object_path",
        help="The full name of the object",
    )
    # find command. Returns the objects that include a specific pattern/ipblock
    find = command.add_parser(
        "find", help="Find which objects include a specific pattern/ipblock in their rule expressions"
    )
    # Scope is none by default, as we might want to search all expression-containing types.
    find.add_argument(
        "--scope",
        "-s",
        help="The requestctl rule scope to search for expressions referencing the entity.",
        choices=SCOPES.keys(),
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
    # Rename command. Renames an object in the datastore.
    # Example: requestctl rename action cache-text/block_cloud cache-text/block_cloud_v2
    rename = command.add_parser("rename", help="Rename an object in the datastore.")
    rename.add_argument("object_type", help="What object type to rename", choices=SYNC_ENTITIES)
    rename.add_argument(
        "old_slug",
        help="The full name of the object to rename, including tags, e.g. cache-text/block_cloud",
    )
    rename.add_argument(
        "new_slug",
        help="The new full name of the object, including tags, e.g. cache-text/block_cloud_v2",
    )
    # Fetch ipblock-source command. Fetches ipblock-source remote URL and updates the corresponding ipblock.
    fetch = command.add_parser("fetch", help="Fetch ipblock-source remote URL and update the corresponding ipblock.")
    fetch.add_argument(
        "object_paths",
        nargs="*",
        help="The full names of the ipblock_source objects, including tags, e.g. known-clients/bad_actors",
    )
    fetch.add_argument(
        "--all",
        "-a",
        help="Fetch all ipblock-sources in a loop",
        action="store_true",
    )
    fetch.add_argument(
        "--verbose",
        "-v",
        help="Print one line for each ipblock-source fetched",
        action="store_true",
    )
    fetch.add_argument("--ignore-errors", help="Continue on errors when fetching ipblock-sources", action="store_true")

    # Fetch an individual api token using the root api token, and save it to the file indicated
    get_api_token = command.add_parser(
        "get-api-token", help="Fetch an API token for a specific client and save it to a file."
    )
    get_api_token.add_argument("--output", "-o", help="The file to save the API token to.", default="")
    get_api_token.add_argument("user", help="The username to fetch the API token for.")

    parsed_args = parser.parse_args(args)

    # Mutually exclusive groups only work for optional arguments. In order to not break with the semantics of the
    # other commands, we need to do some manual validation for "fetch".
    if parsed_args.command == "fetch":
        if parsed_args.all and parsed_args.object_paths:
            parser.error("Cannot specify object_paths when --all is used for fetch command.")
        if not parsed_args.all and not parsed_args.object_paths:
            parser.error("Either --all or at least one object_path must be specified for fetch command.")

    return parsed_args


def apply(parsed_args: Namespace):
    """Apply an object definition from a yaml file to the datastore."""
    p = Path(parsed_args.file)
    if not p.exists() or not p.is_file():
        raise FileNotFoundError(f"File {parsed_args.file} does not exist.")

    payload = yaml.safe_load(p.read_text())

    # If the object contains fields to enable rules, we need to remove those enable fields from the
    # payload. Those fields should only be modified by the enable / disable commands.
    for object_type, enabled_field in SCOPES.values():
        if parsed_args.object_type == object_type and enabled_field in payload:
            del payload[enabled_field]

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

    if parsed_args.reset:
        if sys.stdout.isatty():
            print("WARNING: This will delete all non-derived objects.")
            print("ONLY use this option if you're reloading a full dump " "and you know what you are doing.")

            confirm = input("Do you want to proceed? (y/N): ").strip().lower()
            if confirm != "y":
                print("Aborting reset.")
                sys.exit(1)
        # Reset the expression-containing entities first, as they might depend on the other objects
        deletion_order = [item for sublist in ENTITIES_SYNC_ORDER for item in sublist]
        deletion_order.reverse()
        for entity in deletion_order:
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


def enable(parsed_args: Namespace, enable: bool = True):
    """Enable a request rule in an action or known-client entity. Enable ipblocks to be rendered to haproxy map."""
    object_type, field_name = SCOPES[parsed_args.scope]
    request_url = f"/api/{object_type}/{parsed_args.target}"
    # We can only enable rules that are defined by objects in the datastore, so we assume that this
    # is an update operation.
    try:
        obj = api_call(request_url)
        if obj.get(field_name) == enable:
            print(
                f"{parsed_args.target} in scope {parsed_args.scope} is already {'enabled' if enable else 'disabled'}."
            )
            return
        obj[field_name] = enable
        api_call(request_url, method="PUT", data=obj)
        print(f"{'Enabled' if enable else 'Disabled'} {parsed_args.target} in scope {parsed_args.scope} successfully.")
    except HTTPError as e:
        if e.response.status_code == 404:
            raise ValueError(f"Target {parsed_args.target} not found in scope {parsed_args.scope}.")
        else:
            raise ValueError(
                f"Error enabling {parsed_args.target} in scope {parsed_args.scope}: {e.response.status_code} - {e.response.text}"
            )


def disable(parsed_args: Namespace):
    """Disable a request rule in an action or known-client entity. Disable ipblocks from being rendered to haproxy map."""
    return enable(parsed_args, enable=False)


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
    """Find actions or known-clients that reference a specific pattern or ipblock."""
    search_string = parsed_args.search_string
    if "/" not in search_string:
        raise ValueError("Search string must be in the format <scope>/<name>.")
    if parsed_args.scope:
        object_type, _ = SCOPES[parsed_args.scope]
    else:
        # If no scope is specified, we search all expression-containing entities
        object_type = "all"
    try:
        response = api_call(f"/api/match_expression?q={search_string}&scope={object_type}")
    except HTTPError as e:
        if e.response.status_code == 404:
            print("No entries found.")
            return
        else:
            raise ValueError(f"Error finding objects: {e.response.status_code} - {e.response.text}")
    print(f"Found {len(response.get('matches', []))} objects matching {search_string}:")
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
    commit_hash = response.get("commit_hash")
    if not commit_hash:
        print("No changes to commit.")
        return
    response = api_call(f"/api/commit/{commit_hash}")
    # print(response)
    if not parsed_args.batch:
        print("The following changes will be made:")
        separator = None
        for key, description in [
            ("vcl", "Varnish action VCL"),
            ("haproxy", "HAProxy action DSL"),
            ("haproxy_known_client", "HAProxy known-client DSL"),
        ]:
            if separator is not None:
                print(separator)
            print(f"{description} changes:")
            diffs = None
            if response.get(key):
                diffs = show_diffs(response.get(key))
            if diffs:
                print(diffs)
            else:
                print(f"No changes in {description}.")
            separator = "=="

        confirm = input("Do you want to proceed with the commit? (y/N): ").strip().lower()
        if confirm != "y":
            print("Aborting commit.")
            return
    try:
        response = api_call("/api/commit", method="POST", data={"commit_hash": commit_hash})
        if response.get("status", "nok") == "ok":
            print("Changes committed successfully.")
    except HTTPError as e:
        raise ValueError(f"Error committing changes: {e.response.status_code} - {e.response.text}")


def log(parsed_args: Namespace):
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
    request_url = f"/api/{parsed_args.object_type}/{parsed_args.object_path}/dsl"
    try:
        response = api_call(request_url)
        print(response.get("dsl", "No HAProxy configuration found for this object."))
    except HTTPError as e:
        if e.response.status_code == 404:
            print(f"HAProxy configuration for {parsed_args.object_type}@{parsed_args.object_path} not found.")
        else:
            raise ValueError(f"Error getting HAProxy configuration: {e.response.status_code} - {e.response.text}")


def rename(parsed_args: Namespace):
    """Rename an object in the datastore."""
    request_url = f"/api/{parsed_args.object_type}/{parsed_args.old_slug}/rename"
    try:
        response = api_call(request_url, method="POST", data={"new_slug": parsed_args.new_slug})
        print(response.get("status", "No status found for this action."))
    except HTTPError as e:
        if e.response.status_code == 404:
            raise ValueError(f"Object {parsed_args.old_slug} not found in type {parsed_args.object_type}.")
        elif e.response.status_code == 400:
            raise ValueError(f"Bad request: {e.response.text}")
        else:
            resp_decoded = e.response.json()
            outcome = resp_decoded.get("details")

            raise ValueError(f"Error renaming object: {e.response.status_code} - {outcome}")


def fetch(parsed_args: Namespace):
    """Fetch ipblock-source remote URL and update the corresponding ipblock."""
    if parsed_args.all:
        object_paths = api_call("/api/ipblock_source")
    else:
        object_paths = parsed_args.object_paths

    for object_path in set(sorted(object_paths)):
        request_url = f"/api/ipblock_source/{object_path}/fetch"
        try:
            api_call(request_url, method="POST")
            if parsed_args.verbose:
                print(f"Fetched ipblock_source {object_path}")
        except HTTPError as e:
            if e.response.status_code == 404:
                error_msg = f"ipblock_source {object_path} not found."
            else:
                error_msg = f"Error fetching ipblock_source {object_path}: {e.response.status_code} - {e.response.text}"

            if parsed_args.ignore_errors:
                print(error_msg)
            else:
                raise ValueError(error_msg)


def get_api_token(parsed_args: Namespace):
    """Fetch an API token for a specific client and save it to a file."""
    user = parsed_args.user
    request_url = f"/api/api-tokens"
    response = api_call(request_url)
    api_tokens = response.get("tokens", {})
    if user not in api_tokens:
        raise ValueError(f"User {user} not found in API tokens.")
    api_token = api_tokens[user]

    if parsed_args.output:
        with open(parsed_args.output, "w") as f:
            f.write(api_token)
        print(f"API token for user {user} saved to {parsed_args.output}.")
    else:
        print(f"API token for user {user}: {api_token}")


def main(args=None):
    """Main function to run the requestctl CLI."""
    if args is None:
        args = sys.argv[1:]

    parsed_args = parse_args(args)

    # Set up logging
    logging.basicConfig(level=logging.DEBUG if parsed_args.debug else logging.INFO)
    logger.setLevel(logging.DEBUG if parsed_args.debug else logging.INFO)
    cmd_str = parsed_args.command.replace("-", "_")
    cmd = globals().get(cmd_str)
    if callable(cmd):
        return cmd(parsed_args)
    else:
        raise ValueError(f"{parsed_args.command} is not a valid option.")


if __name__ == "__main__":
    try:
        main()
    except Exception as e:
        logger.error(f"Error occurred: {e}")
        sys.exit(1)
