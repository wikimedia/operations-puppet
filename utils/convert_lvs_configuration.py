#!/usr/bin/env python3
import sys

import yaml


def get_ipblock(ipblock):
    res = {}
    for site, val in ipblock.items():
        if isinstance(val, dict):
            res[site] = val
        else:
            res[site] = {"default": val}
    return res


def get_monitoring(data):
    if "critical" not in data:
        data["critical"] = True

    if "uri" in data:
        data["check_command"] = "check_http_https!{}".format(data["uri"])
        del data["uri"]

    return data


def convert_record(data):
    lvs = {
        "enabled": True,
        "class": data["class"],
        "ip": get_ipblock(data["ip"]),
        "scheduler": data.get("scheduler", "wrr"),
        "conftool": data["conftool"],
        "depool_threshold": data["depool-threshold"],
        "monitors": data["monitors"],
    }
    if "protocol" in data:
        lvs["protocol"] = data["protocol"]

    res = {
        "description": data["description"],
        "sites": data["sites"],
        "port": data.get("port", 80),
        "lvs": lvs,
        "state": "production",
    }
    if "icinga" in data:
        res["monitoring"] = get_monitoring(data["icinga"])
    return res


def main():
    try:
        file_to_convert = sys.argv[1]
    except IndexError:
        print("Need a file to convert from as a command-line argument")
    lvs_config = {}
    with open(file_to_convert, "r") as fh:
        conf = yaml.safe_load(fh)

    lvs_config = conf["lvs::configuration::lvs_services"]
    result_conf = {}
    for label, data in lvs_config.items():
        print("converting " + label)
        result_conf[label] = convert_record(data)
        print("Is this service using TLS?")
        ans = input("> ")
        result_conf[label]["encryption"] = ans in ["y", "Y", "yes", "Yes"]

    try:
        output = sys.argv[2]
        with open(output, "w") as fh:
            yaml.dump({"service::catalog": result_conf}, fh)
    except IndexError:
        yaml.dump({"service::catalog": result_conf}, sys.stderr)


if __name__ == "__main__":
    main()
