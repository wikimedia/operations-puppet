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
            if 'local' in pillar:
                pillar = json.loads(out)['local']
            else:
                pillar = json.loads(out)
            try:
                repo_config = pillar['repo_config'][prefix]
                parent_dir = pillar['deployment_config']['parent_dir']
            except KeyError:
                print ("Missing configuration for repo. "
                       "Have you added it in puppet? Exiting.")
                return False
            options = {'location': '{0}/{1}'.format(parent_dir,
                                                    prefix),
                       'checkout_submodules': False,
                       'dependencies': []}
            for option, default in options.items():
                try:
                    self.__config[option] = repo_config[option]
                except KeyError:
                    self.__config[option] = default
            self.__config['prefix'] = prefix
            return True
        except ValueError:
            print ("JSON data wasn't loaded from the pillar call. "
                   "git-deploy can't configure itself. Exiting.")
            return False

    def get_config(self):
        return self.__config

    def update_repos(self, tag):
        repodir = self.__config['location']
        checkout_submodules = self.__config['checkout_submodules']

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
                                 stdout=subprocess.PIPE,
                                 stderr=subprocess.PIPE)
            out = p.communicate()[0]

        # Ensure repos we depend on are handled
        dependencies = self.__config['dependencies']
        for dependency in dependencies:
            dependency_script = ('/var/lib/git-deploy/dependencies/%s.dep' %
                                 (dependency))
            if os.path.exists(dependency_script):
                dependency_script = (dependency_script + " %s %s" %
                                     (dependency, self.__config['prefix']))
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
        prefix = self.__config['prefix']
        print ("Running: sudo salt-call -l quiet publish.runner "
               "deploy.fetch '%s'" % (prefix))
        p = subprocess.Popen("sudo salt-call -l quiet publish.runner "
                             "deploy.fetch '%s'" % (prefix),
                             shell=True,
                             stdout=subprocess.PIPE)
        out = p.communicate()[0]

    def checkout(self, force):
        prefix = self.__config['prefix']
        print ("Running: sudo salt-call -l quiet publish.runner "
               "deploy.checkout '%s,%s'" % (prefix, force))
        p = subprocess.Popen("sudo salt-call -l quiet publish.runner "
                             "deploy.checkout '%s,%s'" % (prefix, force),
                             shell=True, stdout=subprocess.PIPE)
        out = p.communicate()[0]

    def ask(self, stage, force=False):
        prefix = self.__config['prefix']
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
                    self.fetch()
                if stage == "checkout":
                    self.checkout(force)
