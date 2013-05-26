#!/usr/bin/python
# encoding: utf-8

#####################################################################
### THIS FILE IS MANAGED BY PUPPET
### puppet:///files/cgi-bin/noc/ng/extractprofile.py
#####################################################################

# showprofile
# Copyright (c) 2006 Domas Mituzas

import socket

import xml.sax
from xml.sax import make_parser
from xml.sax.handler import feature_namespaces


# XML SAX parser class, puts stuff into some array!
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
            self.event["onereal"] = self.event["real"] / self.event["count"]
            self.event["onecpu"] = self.event["cpu"] / self.event["count"]

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


class SocketProfile:
    def __init__(self, host='localhost', port=3811):
        self.sock = SocketSource()
        self.sock.connect((host, port))

    def extract(self):
        return ExtractProfile().extract(self.sock)


class SocketSource (socket.socket):
    """Stub class for extending socket object to support file source mechanics"""
    def read(self, what):
        """Alias recv to read, missing in socket.socket"""
        return self.recv(what, 0)

if __name__ == '__main__':
        print "\nNot a valid entry point"
