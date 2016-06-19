from mock import Mock
from assertpy import assert_that
from estool.elastic import Elastic, longest_uptime


def test_longest_uptime():
    nodes_stats = {
        'nodes': {
            'node1': {'jvm': {'uptime_in_millis': 1}},
            'node2': {'jvm': {'uptime_in_millis': 4}},
            'node3': {'jvm': {'uptime_in_millis': 2}},
            'node4': {'jvm': {'uptime_in_millis': 3}},
        }
    }
    assert_that(longest_uptime(nodes_stats)).is_equal_to(4)


def test_longest_uptime_of_empty_node_list_is_zero():
    nodes_stats = {
        'nodes': {}
    }
    assert_that(longest_uptime(nodes_stats)).is_equal_to(0)


def test_single_node_is_longest_running_node():
    es = Mock()
    es.nodes = Mock()
    es.nodes.stats = Mock(side_effect=[
        {
            'nodes': {
                'node1': {'jvm': {'uptime_in_millis': 1}},
            }
        },
        {
            'nodes': {
                'node1': {'jvm': {'uptime_in_millis': 1}},
            }
        }
    ])

    elastic = Elastic(es)

    assert_that(elastic.is_longest_running_node_in_cluster()).is_true()


def test_node_is_longest_running():
    es = Mock()
    es.nodes = Mock()
    es.nodes.stats = Mock(side_effect=[
        {
            'nodes': {
                'node1': {'jvm': {'uptime_in_millis': 1}},
                'node2': {'jvm': {'uptime_in_millis': 4}},
                'node3': {'jvm': {'uptime_in_millis': 2}},
                'node4': {'jvm': {'uptime_in_millis': 3}},
            }
        },
        {
            'nodes': {
                'node2': {'jvm': {'uptime_in_millis': 4}},
            }
        }
    ])

    elastic = Elastic(es)

    assert_that(elastic.is_longest_running_node_in_cluster()).is_true()


def test_node_is_not_longest_running():
    es = Mock()
    es.nodes = Mock()
    es.nodes.stats = Mock(side_effect=[
        {
            'nodes': {
                'node1': {'jvm': {'uptime_in_millis': 1}},
                'node2': {'jvm': {'uptime_in_millis': 4}},
                'node3': {'jvm': {'uptime_in_millis': 2}},
                'node4': {'jvm': {'uptime_in_millis': 3}},
            }
        },
        {
            'nodes': {
                'node1': {'jvm': {'uptime_in_millis': 1}},
            }
        }
    ])

    elastic = Elastic(es)

    assert_that(elastic.is_longest_running_node_in_cluster()).is_false()
