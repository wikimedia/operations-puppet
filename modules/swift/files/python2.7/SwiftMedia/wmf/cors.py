class CORS(object):
    """Poor man's Wildcard CORS support for Swift <= 1.7.4"""

    def __init__(self, app):
        self.app = app

    def __call__(self, env, start_response):
        # no support for other methods, nor for preflighted requests
        if env['REQUEST_METHOD'] not in ('HEAD', 'GET'):
            return self.app(env, start_response)

        # skip if it's an authenticated request, no CORS for them
        if env.get('REMOTE_USER'):
            return self.app(env, start_response)

        def _start_response(status, headers, exc_info=None):
            # support just for the wildcard CORS
            cors = ('Access-Control-Allow-Origin', '*')
            headers.append(cors)
            return start_response(status, headers, exc_info)

        return self.app(env, _start_response)


def filter_factory(global_conf, **local_conf):
    def cors_filter(app):
        return CORS(app)

    return cors_filter

# vim: set expandtab tabstop=4 shiftwidth=4 autoindent:
