#!/usr/bin/env python
#
#  Copyright (C) 2013 Yuvi Panda <yuvipanda@gmail.com>
#
#  Permission to use, copy, modify, and/or distribute this software for any
#  purpose with or without fee is hereby granted, provided that the above
#  copyright notice and this permission notice appear in all copies.
#
#  THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
#  WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
#  MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
#  ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
#  WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
#  ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
#  OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
#
"""
Simple TCP server that keeps routes in the Redis db for authenticated requests.

The routes are kept as long as the socket making the request is open, and cleaned
up right afterwards. identd is used for authentication - while normally that is
a terrible idea, this is okay in the toollabs environment because we only have
a limited number of trusted admins. This also allows routes to be added
only for URLs that are under the URL prefix allocated for the tool making the
request. For example, a tool named 'testtool' can ask only for URLs that
start with /testtool/ to be routed to where it wants.

The socket server is a threaded implementation. Python can not be truly parallel
(hello, GIL!), but for our purposes it is good enough.
"""
import socket
import SocketServer
import logging

import redis


HOST, PORT = "0.0.0.0", 8282

def get_remote_user(remote_host, remote_port, local_port):
    """
    Uses RFC1413 (ident protocol) to identify which user is making the request.

    Returns username if found, None if there was an error.

    This is secure enough for toollabs since we do not have arbitrary admins.
    """
    s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    s.connect((remote_host, 113))

    request = u"%s, %s\n" % (remote_port, local_port)

    s.send(request.encode("ascii"))
    resp = s.recv(256)
    s.close()

    resp_parts = [r.strip() for r in resp.split(":")]
    if "USERID" not in resp_parts:
        # Some auth error has occured. Abort!
        logging.log(logging.INFO, "Identd auth failed, sent %s got back %s" % (request.strip(), resp.strip()))
        return None

    return resp_parts[-1]

class RouteRequestHandler(SocketServer.BaseRequestHandler):
    """
    Handles incoming connections from clients asking for routes.
    """
    def handle(self):
        route = self.request.recv(1024).strip()
        destination = self.request.recv(1024).strip()
        user = get_remote_user(self.client_address[0], self.client_address[1], PORT)

        # For some reason the identd response gave us an error, or failed otherwise
        # This should usually not happen, so we'll just ask folks to 'Contact an administrator'
        if user == None:
            self.request.send("Identd authentication failed. Please contact an administrator")
            self.request.close()
            return

        # Only tool accounts are allowed to ask for routes
        # Assume that *only* tool accounts will have local- prefix
        # Since user accounts need to be approved, and I doubt anything with local-
        # will make it.
        if not user.startswith('local-'):
            self.request.send("This service available only to tool accounts")
            self.request.close()
            return

        toolname = user.replace("local-", "")

        redis_key = "prefix:%s" % toolname

        logging.log(logging.INFO, "Received request from %s for %s to %s", toolname, route, destination)

        red = redis.Redis() # Always connect to localhost
        red.hset(redis_key, route, destination)
        logging.log(logging.DEBUG, "Set redis key %s with key/value %s:%s", redis_key, route, destination)

        while self.request.recv(1) != '':
            pass

        logging.log(logging.INFO, "Cleaning up request from %s for %s to %s", toolname, route, destination)

        red.hdel(redis_key, route)
        logging.log(logging.DEBUG, "Remove redis key %s with key/value %s:%s", redis_key, route, destination)

        self.request.close()

if __name__ == '__main__':
    logging.log(logging.INFO, "Starting server on port %s", PORT)
    server = SocketServer.ThreadingTCPServer((HOST, PORT), RouteRequestHandler)
    server.serve_forever()

