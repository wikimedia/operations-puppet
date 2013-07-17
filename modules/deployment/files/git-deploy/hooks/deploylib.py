#!/usr/bin/python

import os
import subprocess
import json


class DeployLib(object):

    __config = {}

    def __init__(self, prefix):
        self.__fetch_config(prefix)

    def __fetch_config(self, prefix):
        print "Running: sudo salt-call -l quiet --out json pillar.data"
        p = subprocess.Popen("sudo salt-call -l quiet --out json pillar.data",
                             shell=True, stdout=subprocess.PIPE,
                             stderr=subprocess.PIPE)
        out = p.communicate()[0]
        try:
            pillar = json.loads(out)
            options = {'repo_locations': None
                       'repo_checkout_submodules': False,
                       'repo_dependencies': []}
            for option, default in options.items():
                try:
                    __config[option] = pillar[option][prefix]
                except KeyError:
                   if default:
                       __config[option] = default
                   else:
                       print (option + " isn't configured. "
                              "Have you added it in puppet? Exiting.")
                       return False
            __config['prefix'] = prefix
            return True
        except ValueError:
            print ("JSON data wasn't loaded from the pillar call. "
                   "git-deploy can't configure itself. Exiting.")
            return False

    def get_config(self):
        return self.__config

    def update_repos(self, tag):
        repodir = __config['repo_locations']
        checkout_submodules = __config['repo_checkout_submodules']

        # Ensure the fetch will work for the repo
        p = subprocess.Popen('git update-server-info',
                             cwd=repodir + '/.git/', shell=True,
                             stderr=subprocess.PIPE)
        err = p.communicate()[0]
        if err:
            print err
        # Ensure the fetch will work for the submodules
        if checkout_submodules:
            p = subprocess.Popen('git submodule foreach "git tag %s"' % tag,
                                 cwd=repodir, shell=True,
                                 stdout=subprocess.PIPE,
                                 stderr=subprocess.PIPE)
            out = p.communicate()[0]
            p = subprocess.Popen('git submodule foreach '
                                 '"submodule-update-server-info"',
                                 cwd=repodir, shell=True,
                                 stdout=subprocess.PIPE, stderr=subprocess.PIPE)
            out = p.communicate()[0]

        # Ensure repos we depend on are handled
        dependencies = __config['repo_dependencies']
        for dependency in dependencies:
            dependency_script = ('/var/lib/git-deploy/dependencies/%s.dep' %
                                 (dependency))
            if os.path.exists(dependency_script):
                dependency_script = (dependency_script + " %s %s" %
                                     (dependency, __config['prefix']))
                p = subprocess.Popen(dependency_script, shell=True,
                                     stderr=subprocess.PIPE)
                out = p.communicate()[0]
                print out
            else:
                print ("Error: script for dependency '%s' is missing. "
                       "Have you added it in puppet? Exiting." %
                       dependency_script)
                return 1

    def fetch(self):
        prefix = __config['prefix']
        print ("Running: sudo salt-call -l quiet publish.runner "
               "deploy.fetch '%s'" % (prefix))
        p = subprocess.Popen("sudo salt-call -l quiet publish.runner "
                             "deploy.fetch '%s'" % (prefix),
                             shell=True,
                             stdout=subprocess.PIPE)
        out = p.communicate()[0]

    def checkout(self, force):
        prefix = __config['prefix']
        print ("Running: sudo salt-call -l quiet publish.runner "
               "deploy.checkout '%s,%s'" % (prefix, force))
        p = subprocess.Popen("sudo salt-call -l quiet publish.runner "
                             "deploy.checkout '%s,%s'" % (prefix, force),
                             shell=True, stdout=subprocess.PIPE)
        out = p.communicate()[0]

    def ask(self, stage, force=False):
        prefix = __config['prefix']
        if stage == "fetch":
            check = "/usr/local/bin/deploy-info --repo=%s --fetch"
        elif stage == "checkout":
            check = "/usr/local/bin/deploy-info --repo=%s"
        p = subprocess.Popen(check % (prefix), shell=True,
                             stdout=subprocess.PIPE)
        out = p.communicate()[0]
        print out
        while True:
            answer = raw_input("Continue? ([d]etailed/[C]oncise report,"
                               "[y]es,[n]o,[r]etry): ")
            if not answer or answer == "c" or answer == "C":
                p = subprocess.Popen(check % (prefix), shell=True,
                                     stdout=subprocess.PIPE)
                out = p.communicate()[0]
                print out
            elif answer == "d" or answer == "D":
                p = subprocess.Popen(check % (prefix) + " --detailed",
                                     shell=True, stdout=subprocess.PIPE)
                out = p.communicate()[0]
                print out
            elif answer == "Y" or answer == "y":
                return True
            elif answer == "N" or answer == "n":
                return False
            elif answer == "R" or answer == "r":
                if stage == "fetch":
                    fetch()
                if stage == "checkout":
                    checkout(force)
