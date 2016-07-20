# coding=utf-8
"""
Collect a number of metrics about a kubernetes cluster:

  - Number of pods
    - In running & crashloopbackoff states (since pending is too transitionary)
  - Number of nodes
  - Number of replicasets
  - Number of deployments
  - Number of services
  - Number of namespaces

"""
import diamond.collector
import requests


class KubernetesCollector(diamond.collector.Collector):
    def get_default_config(self):
        """
        Returns the default collector settings
        """
        config = super(KubernetesCollector, self).get_default_config()
        config.update({
            'method':   'Threaded',
        })
        return config

    def _get_all(self, kind, apigroup='api/v1'):
        """
        Get a list of all kubernetes objects of kind, across namespaces
        """
        # FIXME: Make the URL configurable
        url = 'http://localhost:8080/{apigroup}/{kind}'.format(kind=kind, apigroup=apigroup)
        return requests.get(
            url,
            headers={'User-Agent': 'Diamond Kubernetes Collector/1.0'}
        ).json()['items']

    def collect(self):
        # Number of nodes
        self.publish('nodes.all', len(self._get_all('nodes')))

        # Number of deployments
        self.publish('deployments.all', len(self._get_all('deployments', 'apis/extensions/v1beta1')))

        # Number of services
        self.publish('services.all', len(self._get_all('services')))

        # Number of namespaces
        self.publish('namespaces.all', len(self._get_all('namespaces')))

        # Pod stats:
        #  - Total number of pods
        #  - Pods in various states
        #  - Number of namespaces with at least one pod in them
        pods = self._get_all('pods')
        pod_phases = {}
        active_namespaces = set()
        for pod in pods:
            phase = pod['status']['phase'].lower()
            namespace = pod['metadata']['namespace']
            if namespace not in active_namespaces:
                active_namespaces.add(namespace)
            pod_phases[phase] = pod_phases.get(phase, 0) + 1

        self.publish('pods.all', len(pods))
        for phase, count in pod_phases.items():
            self.publish('pods.' + phase, count)

        self.publish('namespaces.active', len(active_namespaces))
