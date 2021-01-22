#!/usr/bin/env python3

import sys
import yaml
from argparse import ArgumentParser, Namespace

import requests


class EncError(Exception):
    pass


class EncConnection:
    def __init__(self, enc_url, openstack_project):
        self.enc_url = enc_url
        self.openstack_project = openstack_project

    def get_project_hiera(self) -> requests.Response:
        # the api expects an empty space as prefix to get the global
        # openstack_project data
        return self.get_prefix_hiera(prefix=" ")

    def get_prefix_hiera(self, prefix: str) -> requests.Response:
        response = requests.get(
            "{0}/{1}/prefix/{2}/hiera".format(
                self.enc_url,
                self.openstack_project,
                prefix,
            )
        )
        if not response.ok:
            raise EncError(
                f"Unable to get prefix data for "
                f"enc_url='{self.enc_url}', "
                f"prefix='{prefix}', "
                f"openstack_project='{self.openstack_project}'"
                f"\n{response}"
            )

        return response

    def set_prefix_hiera(self, prefix: str, data: str) -> requests.Response:
        response = requests.post(
            "{0}/{1}/prefix/{2}/hiera".format(
                self.enc_url,
                self.openstack_project,
                prefix,
            ),
            # make sure it's pretty formatted
            yaml.dump(yaml.load(data, Loader=yaml.SafeLoader)),
        )
        if not response.ok:
            raise EncError(
                f"Unable to set prefix data for "
                f"enc_url='{self.enc_url}', "
                f"prefix='{prefix}', "
                f"openstack_project='{self.openstack_project}'"
                f"data=data"
                f"\n{response}"
            )

        return response

    def get_node_consolidated_info(self, fqdn: str) -> requests.Response:
        """
        This gives the results of applying all the openstack_project + prefix
        + node configs, ready to be used by puppet.
        """
        response = requests.get(
            "{0}/{1}/node/{2}".format(
                self.enc_url,
                self.openstack_project,
                fqdn,
            )
        )
        if not response.ok:
            raise EncError(
                f"Unable to get node info data for "
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
        response = requests.get(
            "{0}/{1}/prefix/{2}".format(
                self.enc_url,
                self.openstack_project,
                fqdn,
            )
        )
        if not response.ok:
            raise EncError(
                f"Unable to get node info data for "
                f"enc_url='{self.enc_url}', "
                f"fqdn='{fqdn}', "
                f"openstack_project='{self.openstack_project}'"
                f"\n{response}"
            )

        return response


def main(args: Namespace) -> int:
    enc_connection = EncConnection(
        enc_url=args.enc_url,
        openstack_project=args.openstack_project,
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
        "--enc-url",
        default="http://puppetmaster.cloudinfra.wmflabs.org:8101/v1",
        help=(
            "Full url to the enc, for example "
            "http://puppetmaster.cloudinfra.wmflabs.org:8101/v1"
        ),
    )
    parser.add_argument("--openstack-project")
    parser.add_argument("action", choices=available_actions)
    parser.add_argument(
        "params",
        nargs="*",
        help="Any parameters needed for the action chosen.",
    )

    sys.exit(main(parser.parse_args()))
