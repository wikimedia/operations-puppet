#!/usr/bin/python
# PBR Generated from u'wsgi_scripts'

import threading

# This import is so our custom monkeypatch(es)
#  get loaded before anything else.  The rest
#  of this file is the same as the packaged
#  upstream usgi script.
import wmfkeystonehooks.wmfkeystonehooks  # noqa: F401

from keystone.server.wsgi import initialize_admin_application

if __name__ == "__main__":
    import argparse
    import socket
    import sys
    import wsgiref.simple_server as wss

    my_ip = socket.gethostbyname(socket.gethostname())
    parser = argparse.ArgumentParser(
        description=initialize_admin_application.__doc__,
        formatter_class=argparse.ArgumentDefaultsHelpFormatter,
        usage='%(prog)s [-h] [--port PORT] -- [passed options]')
    parser.add_argument('--port', '-p', type=int, default=8000,
                        help='TCP port to listen on')
    parser.add_argument('args',
                        nargs=argparse.REMAINDER,
                        metavar='-- [passed options]',
                        help="'--' is the separator of the arguments used "
                        "to start the WSGI server and the arguments passed "
                        "to the WSGI application.")
    args = parser.parse_args()
    if args.args:
        if args.args[0] == '--':
            args.args.pop(0)
        else:
            parser.error("unrecognized arguments: %s" % ' '.join(args.args))
    sys.argv[1:] = args.args
    server = wss.make_server('', args.port, initialize_admin_application())

    print("*" * 80)
    print("STARTING test server keystone.server.wsgi.initialize_admin_application")
    url = "http://%s:%d/" % (my_ip, server.server_port)
    print("Available at %s" % url)
    print("DANGER! For testing only, do not use in production")
    print("*" * 80)
    sys.stdout.flush()

    server.serve_forever()
else:
    application = None
    app_lock = threading.Lock()

    with app_lock:
        if application is None:
            application = initialize_admin_application()
