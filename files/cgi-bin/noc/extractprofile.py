#!/usr/bin/python
# encoding: utf-8

#####################################################################
### THIS FILE IS MANAGED BY PUPPET
### puppet:///files/cgi-bin/noc/extractprofile.py
#####################################################################

# showprofile
# Copyright (c) 2006 Domas Mituzas

import xml.sax
from xml.sax import make_parser
from xml.sax.handler import feature_namespaces


class ExtractProfile(xml.sax.handler.ContentHandler):
    def __init__(self):
        self.parser = make_parser()
        self.parser.setFeature(feature_namespaces, 0)
        self.parser.setContentHandler(self)

    def startElement(self, name, attrs):
        if name == "db":
            self.db = attrs.get("name")
            self.profile[self.db] = {}
        if name == "host":
            self.host = attrs.get("name")
            self.profile[self.db][self.host] = {}
        if name == "eventname":
            self.inContent = 1
            self.contentData = []
        if name == "stats":
            self.event["count"] = int(attrs.get("count"))
        if name == "cputime":
            self.event["cpu"] = float(attrs.get("total"))
            self.event["cpusq"] = float(attrs.get("totalsq"))
        if name == "realtime":
            self.event["real"] = float(attrs.get("total"))
            self.event["realsq"] = float(attrs.get("totalsq"))

    def endElement(self, name):
        if name == "eventname":
            self.inContent = 0
            self.eventname = "".join(self.contentData)
            self.profile[self.db][self.host][self.eventname] = {}
            self.event = self.profile[self.db][self.host][self.eventname]
        if name == "stats":
            if self.event["count"]:
                self.event["onereal"] = self.event["real"] / self.event["count"]
                self.event["onecpu"] = self.event["cpu"] / self.event["count"]
            else:
                self.event["onereal"] = 0
                self.event["onecpu"] = 0

    def characters(self, chars):
        if self.inContent:
            self.contentData.append(chars)

    def getProfile(self):
        return self.profile

    def extract(self, file=False):
        if not file:
            file = open("profile.xml")
        self.profile = {}
        self.inContent = 0
        self.parser.parse(file)
        return self.profile

if __name__ == '__main__':
        print "\nNot a valid entry point"
