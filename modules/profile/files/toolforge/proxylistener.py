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

The routes are kept as long as the socket making the request is open, and
cleaned up right afterwards. identd is used for authentication - while normally
that is a terrible idea, this is okay in the toollabs environment because we
only have a limited number of trusted admins. This also allows routes to be
added only for URLs that are under the URL prefix allocated for the tool making
the request. For example, a tool named 'testtool' can ask only for URLs that
start with /testtool/ to be routed to where it wants.

The socket server is a threaded implementation. Python can not be truly
parallel (hello, GIL!), but for our purposes it is good enough.
"""
import logging
import socket
import SocketServer

import redis


HOST, PORT = "0.0.0.0", 8282
LOG_FILE = "/var/log/proxylistener"
LOG_FORMAT = "%(asctime)s %(message)s"

logging.basicConfig(filename=LOG_FILE, format=LOG_FORMAT, level=logging.DEBUG)

with open('/etc/wmflabs-project', 'r') as f:
    projectprefix = f.read().strip() + '.'


def get_remote_user(remote_host, remote_port, local_port):
    """
    Uses RFC1413 (ident protocol) to identify which user is making the request.

    Returns username if found, None if there was an error.

    This is secure enough for toollabs since we do not have arbitrary admins.
    """
    s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    s.connect((remote_host, 113))

    request = u"%s,%s\n" % (remote_port, local_port)

    s.send(request.encode("ascii"))
    resp = s.recv(256)
    s.close()

    resp_parts = [r.strip() for r in resp.split(":")]
    if "USERID" not in resp_parts:
        # Some auth error has occurred. Abort!
        logging.log(logging.INFO, "Identd auth failed, sent %s got back %s" %
                    (request.strip(), resp.strip()))
        return None

    return resp_parts[-1]


class RouteRequestHandler(SocketServer.StreamRequestHandler):
    """
    Handles incoming connections from clients asking for routes.
    """
    def handle(self):

        user = get_remote_user(self.client_address[0],
                               self.client_address[1], PORT)
        # For some reason the identd response gave an error or failed otherwise
        # This should usually not happen, so we'll just ask folks to 'Contact
        # an administrator'
        if user is None:
            self.request.send("Identd authentication failed. " +
                              "Please contact an administrator")
            self.request.close()
            return

        # Only tool accounts are allowed to ask for routes
        if not user.startswith(projectprefix):
            self.request.send("This service available only to tool accounts")
            self.request.close()
            return

        toolname = user[len(projectprefix):]

        redis_key = "prefix:%s" % toolname

        command = self.rfile.readline().strip()
        route = self.rfile.readline().strip()
        red = redis.Redis()  # Always connect to localhost

        if command == 'register':
            destination = self.rfile.readline().strip()
            logging.log(logging.INFO, "Received request from %s for %s to %s",
                        toolname, route, destination)

            red.hset(redis_key, route, destination)
            logging.log(logging.DEBUG, "Set redis key %s with key/value %s:%s",
                        redis_key, route, destination)
            self.request.send('ok')

        elif command == 'unregister':
            logging.log(logging.INFO, "Cleaning up request from %s for %s",
                        toolname, route)

            red.hdel(redis_key, route)
            logging.log(logging.DEBUG, "Removed redis key %s with key %s",
                        redis_key, route)
            self.request.send('ok')
        else:
            logging.log(logging.ERROR, "Unknown command received: %s", command)
            self.request.send('fail')

        self.request.close()


if __name__ == '__main__':
    logging.log(logging.INFO, "Starting server on port %s", PORT)
    server = SocketServer.ThreadingTCPServer((HOST, PORT), RouteRequestHandler)
    server.serve_forever()
