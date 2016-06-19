from mock import Mock
from assertpy import assert_that
from estool.elastic import Elastic


def test_banned_nodes_are_joined_and_set_settings_is_called():
    es = Mock()
    es.cluster = Mock()
    es.cluster.put_settings = Mock(return_value={'acknowledged': True})
    elastic = Elastic(es)

    elastic.set_banned_nodes(['node1', 'node2'], '_host')

    es.cluster.put_settings.assert_called_once_with(body={
        'transient': {
            'cluster.routing.allocation.exclude._host': 'node1,node2'
        }
    })


def test_banned_nodes_are_read_from_settings():
    es = Mock()
    es.cluster = Mock()
    es.cluster.get_settings = Mock(return_value={
        'transient': {
            'cluster': {
                'routing': {
                    'allocation': {
                        'exclude': {
                            '_host': 'node1,node2'
                        }
                    }
                }
            }
        }
    })
    elastic = Elastic(es)

    banned_nodes = elastic.get_banned_nodes('_host')

    assert_that(banned_nodes).is_equal_to(['node1', 'node2'])


def test_empty_node_list_if_nodes_not_found():
    es = Mock()
    es.cluster = Mock()
    es.cluster.get_settings = Mock(return_value={
        'nonexistent': 'no-nodes'
    })
    elastic = Elastic(es)

    banned_nodes = elastic.get_banned_nodes('_host')

    assert_that(banned_nodes).is_equal_to([])
