from assertpy.assertpy import assert_that
from mock import Mock

from estool.elastic import Elastic


def test_cluster_status_is_returned():
    es = mock_elasticsearch_status('some_status')
    elastic = Elastic(es)
    assert_that(elastic.cluster_health()).is_equal_to('some_status')


def test_cluster_is_healthy_when_green():
    es = mock_elasticsearch_status()
    elastic = Elastic(es)
    assert_that(elastic.is_cluster_healthy()).is_true()


def test_cluster_is_unhealthy_when_yellow_or_red():
    es = mock_elasticsearch_status('yellow')
    elastic = Elastic(es)
    assert_that(elastic.is_cluster_healthy()).is_false()

    es = mock_elasticsearch_status('red')
    elastic = Elastic(es)
    assert_that(elastic.is_cluster_healthy()).is_false()


def test_exception_mean_cluster_is_unhealthy():
    es = Mock()
    es.cluster = Mock()
    es.cluster.health = Mock(side_effect=Exception)
    elastic = Elastic(es)
    assert_that(elastic.is_cluster_healthy()).is_false()


def mock_elasticsearch_status(status='green'):
    es = Mock()
    es.cluster = Mock()
    es.cluster.health = Mock(return_value={'status': status})
    return es


def test_cluster_status_is_returned():
    es = Mock()
    es.cluster = Mock()
    es.cluster.health = Mock(return_value={
        'status': 'green',
        'number_of_nodes': 24,
        'unassigned_shards': 0,
        'number_of_pending_tasks': 0,
        'number_of_in_flight_fetch': 0,
        'timed_out': False,
        'active_primary_shards': 2983,
        'task_max_waiting_in_queue_millis': 0,
        'cluster_name': 'production-search-codfw',
        'relocating_shards': 0,
        'active_shards_percent_as_number': 100.0,
        'active_shards': 9010,
        'initializing_shards': 0,
        'number_of_data_nodes': 24,
        'delayed_unassigned_shards': 0
    })
    elastic = Elastic(es)
    cluster_status = elastic.cluster_status()

    for line in cluster_status:
        print(line)
