"""External backends that reads hosts from a file."""
import pyparsing as pp

from ClusterShell.NodeSet import NodeSet, RESOLVER_NOGROUP
from cumin.backends import BaseQuery, InvalidQueryError


def grammar():
    """Define the query grammar for the external backend that reads host files."""
    return pp.Group(pp.Word(pp.alphanums + '.-_/()')('filename'))


class HostsFileQuery(BaseQuery):
    """Hosts file backend query class."""

    grammar = grammar()
    """:py:class:`pyparsing.ParserElement`: load the grammar parser only once in a singleton way."""

    def __init__(self, config):
        """Query constructor for the test external backend.

        :Parameters:
            according to parent :py:meth:`cumin.backends.BaseQuery.__init__`.

        """
        super().__init__(config)
        self.hosts = NodeSet(resolver=RESOLVER_NOGROUP)

    def _execute(self):
        """Concrete implementation of parent abstract method.

        :Parameters:
            according to parent :py:meth:`cumin.backends.BaseQuery._execute`.

        Returns:
            ClusterShell.NodeSet.NodeSet: with the FQDNs of the matching hosts.

        """
        return self.hosts

    def _parse_token(self, token):
        """Concrete implementation of parent abstract method.

        :Parameters:
            according to parent :py:meth:`cumin.backends.BaseQuery._parse_token`.
        """
        if isinstance(token, str):
            return

        token_dict = token.asDict()
        try:
            with open(token_dict['filename'], 'r') as f:
                self.hosts = NodeSet.fromlist(f.readlines(), resolver=RESOLVER_NOGROUP)
        except Exception as e:
            raise InvalidQueryError(e)


GRAMMAR_PREFIX = 'F'
""":py:class:`str`: the prefix associate to this grammar, to register this backend into the general
grammar. Required by the backend auto-loader in :py:meth:`cumin.grammar.get_registered_backends`."""

query_class = HostsFileQuery  # pylint: disable=invalid-name
"""Required by the backend auto-loader in :py:meth:`cumin.grammar.get_registered_backends`."""
