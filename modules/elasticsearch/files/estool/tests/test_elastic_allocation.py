from assertpy.assertpy import assert_that
from mock import Mock

from estool.elastic import Elastic

def test_allocated_state_all():
    es = Mock()
    es.cluster = Mock()
    es.cluster.put_settings = Mock(return_value={"acknowledged":True})

    elastic = Elastic(es)
    elastic.set_allocation_state("all")

    es.cluster.put_settings.assert_called_once_with(body={
        'transient': {
            'cluster.routing.allocation.enable': 'all'
        }
    })


def test_allocated_state_primaries():
    es = Mock()
    es.cluster = Mock()
    es.cluster.put_settings = Mock(return_value={"acknowledged": True})

    elastic = Elastic(es)
    elastic.set_allocation_state("primaries")

    es.cluster.put_settings.assert_called_once_with(body={
        'transient': {
            'cluster.routing.allocation.enable': 'primaries'
        }
    })


def test_allocated_state_new_primaries():
    es = Mock()
    es.cluster = Mock()
    es.cluster.put_settings = Mock(return_value={"acknowledged": True})

    elastic = Elastic(es)
    elastic.set_allocation_state("new_primaries")

    es.cluster.put_settings.assert_called_once_with(body={
        'transient': {
            'cluster.routing.allocation.enable': 'new_primaries'
        }
    })


def test_allocated_state_none():
    es = Mock()
    es.cluster = Mock()
    es.cluster.put_settings = Mock(return_value={"acknowledged": True})

    elastic = Elastic(es)
    elastic.set_allocation_state("none")

    es.cluster.put_settings.assert_called_once_with(body={
        'transient': {
            'cluster.routing.allocation.enable': 'none'
        }
    })
