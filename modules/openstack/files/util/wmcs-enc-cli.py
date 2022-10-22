#!/usr/bin/env python3

import sys
import yaml
from argparse import ArgumentParser, Namespace

import mwopenstackclients
import requests


def get_url(clients, project):
    keystone = clients.keystoneclient()
    proxy = keystone.services.list(type="puppet-enc")[0]
    endpoint = keystone.endpoints.list(
        service=proxy.id, interface="public", enabled=True
    )[0]
    enc_api_url = endpoint.url.replace("$(project_id)s", project)
    session = clients.session(project)

    return enc_api_url, session


class EncError(Exception):
    pass


class EncConnection:
    def __init__(self, clients, openstack_project):
        self.enc_url, self.session = get_url(clients, openstack_project)
        self.openstack_project = openstack_project

    def get_project_hiera(self) -> requests.Response:
        # the api expects an empty space as prefix to get the global
        # openstack_project data
        return self.get_prefix_hiera(prefix=" ")

    def get_prefix_hiera(self, prefix: str) -> requests.Response:
        response = self.session.get(
            "{0}/prefix/{1}/hiera".format(
                self.enc_url,
                prefix,
            ),
            headers={"Accept": "application/x-yaml"},
            raise_exc=False,
        )
        if not response.ok:
            raise EncError(
                "Unable to get prefix data for "
                f"enc_url='{self.enc_url}', "
                f"prefix='{prefix}', "
                f"openstack_project='{self.openstack_project}'"
                f"\n{response}"
            )

        return response

    def set_prefix_hiera(self, prefix: str, data: str) -> requests.Response:
        response = self.session.post(
            "{0}/prefix/{1}/hiera".format(
                self.enc_url,
                prefix,
            ),
            data=yaml.dump(yaml.safe_load(data)),
            headers={
                "Content-Type": "application/x-yaml",
                "Accept": "application/x-yaml",
            },
            raise_exc=False,
        )
        if not response.ok:
            raise EncError(
                "Unable to set prefix data for "
                f"enc_url='{self.enc_url}', "
                f"prefix='{prefix}', "
                f"openstack_project='{self.openstack_project}'"
                f"data={data}"
                f"\n{response}"
            )

        return response

    def set_prefix_roles(self, prefix: str, data: str) -> requests.Response:
        response = self.session.post(
            "{0}/prefix/{1}/roles".format(
                self.enc_url,
                prefix,
            ),
            headers={
                "Content-Type": "application/x-yaml",
                "Accept": "application/x-yaml",
            },
            data=yaml.dump(yaml.safe_load(data)),
            raise_exc=False,
        )
        if not response.ok:
            raise EncError(
                "Unable to set roles for "
                f"enc_url='{self.enc_url}', "
                f"prefix='{prefix}', "
                f"openstack_project='{self.openstack_project}'"
                f"data={data}"
                f"\n{response}"
            )

        return response

    def get_node_consolidated_info(self, fqdn: str) -> requests.Response:
        """
        This gives the results of applying all the openstack_project + prefix
        + node configs, ready to be used by puppet.
        """
        response = self.session.get(
            "{0}/node/{1}".format(
                self.enc_url,
                fqdn,
            ),
            headers={"Accept": "application/x-yaml"},
            raise_exc=False,
        )
        if not response.ok:
            raise EncError(
                "Unable to get node info data for "
                f"enc_url='{self.enc_url}', "
                f"fqdn='{fqdn}', "
                f"openstack_project='{self.openstack_project}'"
                f"\n{response}"
            )

        return response

    def get_node_info(self, fqdn: str) -> requests.Response:
        """
        This gives only the specific hiera for the host, that will override
        the ones for the prefix and openstack_project.
        """
        # Yep, we treat the hostname as a prefix itself
        response = self.session.get(
            "{0}/prefix/{1}".format(
                self.enc_url,
                fqdn,
            ),
            headers={"Accept": "application/x-yaml"},
            raise_exc=False,
        )
        if not response.ok:
            raise EncError(
                "Unable to get node info data for "
                f"enc_url='{self.enc_url}', "
                f"fqdn='{fqdn}', "
                f"openstack_project='{self.openstack_project}'"
                f"\n{response}"
            )

        return response


def main(args: Namespace) -> int:
    enc_connection = EncConnection(
        mwopenstackclients.Clients(envfile=args.envfile), args.openstack_project
    )

    fn = getattr(enc_connection, args.action)
    res = fn(*args.params)
    res.raise_for_status()
    print(res.text)
    return 0


if __name__ == "__main__":
    parser = ArgumentParser()
    available_actions = [
        action for action in dir(EncConnection) if not action.startswith("_")
    ]
    parser.add_argument(
        "--envfile",
        default="/etc/novaadmin.yaml",
        help="Path to OpenStack authentication YAML file",
    )
    parser.add_argument("--openstack-project")
    parser.add_argument("action", choices=available_actions)
    parser.add_argument(
        "params",
        nargs="*",
        help="Any parameters needed for the action chosen.",
    )

    sys.exit(main(parser.parse_args()))
