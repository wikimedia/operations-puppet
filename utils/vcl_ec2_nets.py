#!/usr/bin/env python
# Print a Varnish ACL with all EC2 IP ranges as published by Amazon

import requests

url = "https://ip-ranges.amazonaws.com/ip-ranges.json"

ips = requests.get(url).json()["prefixes"]

# Some other values for item["service"] are "AMAZON", "CLOUDFRONT", "S3"
ec2_nets = [item["ip_prefix"] for item in ips if item["service"] == "EC2"]

print("acl aws_nets {")

for net in ec2_nets:
    print('\t"{}";'.format(net))

print("}")
