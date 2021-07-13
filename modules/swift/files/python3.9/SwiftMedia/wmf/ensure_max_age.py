from swift.common import swob


class EnsureMaxAge(object):
    def __init__(self, app, conf):
        self.app = app
        self.methods_list = conf.get("methods_list", "HEAD GET").split()
        self.status_list = conf.get("status_list", "200").split()
        self.max_age = conf.get("max_age", "86400")
        self.host_list = conf.get("host_list", "upload.wikimedia.org").split()

    def __call__(self, env, start_response):
        if env["REQUEST_METHOD"] not in self.methods_list:
            return self.app(env, start_response)

        req = swob.Request(env)
        # Only requests for the configured Host
        if req.host not in self.host_list:
            return self.app(env, start_response)

        def _start_response(status, headers, exc_info=None):
            status_code = status.split()[0]
            if status_code in self.status_list and "Cache-Control" not in headers:
                cc = "public, max-age={}".format(self.max_age)
                headers.append(("Cache-Control", cc))
            return start_response(status, headers, exc_info)

        return self.app(env, _start_response)


def filter_factory(global_conf, **local_conf):
    conf = global_conf.copy()
    conf.update(local_conf)

    def ensure_max_age_filter(app):
        return EnsureMaxAge(app, conf)

    return ensure_max_age_filter


# vim: set expandtab tabstop=4 shiftwidth=4 autoindent:
