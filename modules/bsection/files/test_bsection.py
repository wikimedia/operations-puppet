# SPDX-License-Identifier: Apache-2.0
import io

import pytest

import bsection

TEST_LINE_LEN = 16
TEST_NUM_LINES = 100
TEST_LEN = TEST_LINE_LEN * TEST_NUM_LINES
TEST_MAX_IDX = TEST_LEN - 1


def mk_test_data():
    s = []
    for i in range(TEST_NUM_LINES):
        piece = "%03d data %03d___\n" % (i, i)
        assert len(piece) == TEST_LINE_LEN
        s.append(piece)
    b = "".join(s).encode("utf-8")
    assert len(b) == TEST_LEN
    return b


@pytest.mark.parametrize(
    "needle,exp_min,exp_max",
    [
        ("000 ", 0, None),
        ("abc", -1, None),
        ("0000", -1, None),
        ("100 ", -1, None),
        ("0", TEST_LINE_LEN * 49, TEST_LINE_LEN * 51),
        ("05", TEST_LINE_LEN * 50, TEST_LINE_LEN * 59),
        ("054", TEST_LINE_LEN * 54, None),
        ("099", TEST_LINE_LEN * 99, None),
    ],
)
def test_find_needle(needle, exp_min, exp_max):
    if exp_max is None:
        exp_max = exp_min
    f = io.BytesIO(mk_test_data())
    assert exp_min <= bsection.find_needle(f, needle) <= exp_max


@pytest.mark.parametrize(
    "needle,end_line,expected_line",
    [
        ("000 ", 0, 0),
        ("03", 35, 30),
        ("0", 50, 0),
        ("05", 50, 50),
        ("05", 55, 50),
        ("05", 59, 50),
        ("054", 54, 54),
        ("099", 99, 99),
    ],
)
def test_lower_bound(needle, end_line, expected_line):
    expected = expected_line * TEST_LINE_LEN
    f = io.BytesIO(mk_test_data())
    assert bsection.lower_bound(f, needle, end_line * TEST_LINE_LEN) == expected


@pytest.mark.parametrize(
    "needle,start,expected",
    [
        ("000 ", 0, TEST_LINE_LEN),
        ("0", TEST_LINE_LEN * TEST_NUM_LINES / 2, TEST_LEN),
        ("05", TEST_LINE_LEN * TEST_NUM_LINES / 2, TEST_LINE_LEN * 60),
        ("054", TEST_LINE_LEN * 54, TEST_LINE_LEN * 55),
        ("099", TEST_LINE_LEN * 99, TEST_LEN),
    ],
)
def test_upper_bound(needle, start, expected):
    f = io.BytesIO(mk_test_data())
    assert bsection.upper_bound(f, needle, int(start)) == expected


def test_max_pos():
    f = io.BytesIO(mk_test_data())
    pos_max = bsection.max_pos(f)
    assert pos_max == TEST_MAX_IDX
    assert f.tell() == 0


@pytest.mark.parametrize(
    "index,expected",
    [
        (0, 0),
        (7, 0),
        (TEST_LINE_LEN, TEST_LINE_LEN),
        (TEST_MAX_IDX, TEST_LEN - TEST_LINE_LEN),
    ],
)
def test_find_line_start(index, expected):
    f = io.BytesIO(mk_test_data())
    print(f.readline())
    # Ensure the given index is within the test data.
    assert index <= bsection.max_pos(f)
    f.seek(index)
    assert bsection.find_line_start(f) == expected, f.readline().rstrip(b"\n")


@pytest.mark.parametrize(
    "index,needle,expected",
    [
        (0, "0", 0),
        (0, "01", 1),
        (TEST_LINE_LEN, "000", -1),
        (TEST_LINE_LEN, "0", 0),
        (TEST_LINE_LEN, "001", 0),
        (TEST_LINE_LEN, "001 ", 0),
        (TEST_LINE_LEN, "001 data 001", 0),
        (TEST_LINE_LEN * 99, "099", 0),
    ],
)
def test_check_needle(index, needle, expected):
    f = io.BytesIO(mk_test_data() + b"\n")
    f.seek(index)
    assert bsection.check_needle(f, needle) == expected


def test_peek_line():
    f = io.BytesIO(mk_test_data())
    index = TEST_LINE_LEN
    f.seek(index)
    assert bsection.peek_line(f) == "001 data 001___\n"
    assert f.tell() == index
