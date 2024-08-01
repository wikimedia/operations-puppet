# SPDX-License-Identifier: Apache-2.0

from keystone.identity import generator


class Generator(generator.IDGenerator):

    def generate_public_ID(self, mapping):
        return mapping['local_id']
