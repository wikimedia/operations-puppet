from mock import Mock
from assertpy import assert_that
from estool.elastic import retry, ElasticException


def test_retry_works_the_first_time():
    action = Mock(return_value=True)

    assert_that(retry(action)).is_true()
    action.assert_called_once()


def test_retry_works_after_multiple_failures():
    action = Mock(side_effect=[RuntimeError, RuntimeError, True])

    assert_that(retry(action, sleep_between_attempts=0)).is_true()
    assert_that(action.call_count).is_equal_to(3)


def test_retry_gives_up_after_max_attempts():
    action = Mock(side_effect=RuntimeError)

    try:
        retry(action, sleep_between_attempts=0, max_attempts=5)
        assert False, "exception should have been raised by retry"
    except ElasticException as ex:
        assert_that(ex.message).contains("Number of attempts exceeded")
    finally:
        assert_that(action.call_count).is_equal_to(5)
