#!/usr/bin/env python
# -*- coding: utf-8 -*-

import pytest
from estool.skeleton import fib

__author__ = "Guillaume Lederrey"
__copyright__ = "Guillaume Lederrey"
__license__ = "none"


def test_fib():
    assert fib(1) == 1
    assert fib(2) == 1
    assert fib(7) == 13
    with pytest.raises(AssertionError):
        fib(-10)
