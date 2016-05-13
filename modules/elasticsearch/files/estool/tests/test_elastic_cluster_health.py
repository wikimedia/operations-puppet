from mock import MagicMock, Mock

from estool.elastic import Elastic


def test_cluster_status_is_returned():
    es = mock_elastisearch_status('some_status')
    elastic = Elastic(es)
    assert elastic.cluster_health() == 'some_status'


def test_cluster_is_healthy_when_green():
    es = mock_elastisearch_status()
    elastic = Elastic(es)
    assert elastic.is_cluster_healthy()


def test_cluster_is_unhealthy_when_yellow_or_red():
    es = mock_elastisearch_status('yellow')
    elastic = Elastic(es)
    assert not elastic.is_cluster_healthy()

    es = mock_elastisearch_status('red')
    elastic = Elastic(es)
    assert not elastic.is_cluster_healthy()


def test_exception_mean_cluster_is_unhealthy():
    es = Mock()
    es.cluster = Mock()
    es.cluster.health = Mock(side_effect=Exception)
    elastic = Elastic(es)
    assert not elastic.is_cluster_healthy()


def mock_elastisearch_status(status='green'):
    es = Mock()
    es.cluster = Mock()
    es.cluster.health = Mock(return_value={'status': status})
    return es
