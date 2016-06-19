from mock import Mock
from assertpy import assert_that
from pytest import fail

from estool.estool import EsTool, EsToolException

def test_banned_node_undef():
    es = Mock()
    estool = EsTool(es)
    try:
        estool.ban_node('')
        fail()
    except EsToolException as ete:
        assert_that(ete.message).is_equal_to("No node provided")


def test_ban_node_allowed():
    es = Mock()
    es.get_banned_nodes = Mock(return_value = [])
    es.set_banned_nodes = Mock(return_value = True)

    estool = EsTool(es)

    estool.ban_node('node1')
    es.set_banned_nodes.assert_called_once_with(['node1'], '_host')


def test_ban_banned_node():
    es = Mock()
    es.get_banned_nodes = Mock(return_value = ['node1'])
    es.set_banned_nodes = Mock()

    estool = EsTool(es)

    estool.ban_node('node1')
    es.set_banned_nodes.assert_not_called()

