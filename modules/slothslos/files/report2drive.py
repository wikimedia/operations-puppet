#!/usr/bin/env python3
# SPDX-License-Identifier: Apache-2.0

"""
Small script to automatically download SLO reports from Grafana and upload them
to Google Drive.
"""

import configparser
import logging
import sys
from datetime import datetime, timezone
from io import BytesIO
from typing import Tuple

import click
import requests
import urllib3
from dateutil.relativedelta import relativedelta
from google.auth.exceptions import GoogleAuthError
from google.oauth2 import service_account
from googleapiclient.discovery import build
from googleapiclient.errors import HttpError
from googleapiclient.http import MediaIoBaseUpload
from requests.exceptions import RequestException
from urllib3.exceptions import InsecureRequestWarning
from wmflib.requests import http_session

logger = logging.getLogger()
log_format = logging.Formatter(
    "%(levelname)-2s %(name)s %(funcName)s - %(message)s"
)
sh = logging.StreamHandler()
sh.setFormatter(log_format)
logger.addHandler(sh)
logger.setLevel(logging.INFO)


class HTTPClient:
    """
    The class is a wrapper around the `requests` library to provide
    an implementation of a HTTP client with retry logic and
    connection pooling.
    """

    def __init__(
        self,
        retries: int = 3,
        backoff_factor: float = 1.0,
        timeout: float = 30.0,
        sslverify: bool = True,
    ):
        """
        Initializes the HTTP client with retry logic and connection pooling.

        Args:
            retries (int): the number of retries for failed requests
            backoff_factor (float): the backoff factor for retries
            timeout (float): the timeout for requests
            sslverify (bool): whether to verify SSL certificates
        """
        self.timeout = timeout
        self.sslverify = sslverify

        if self.sslverify is False:
            urllib3.disable_warnings(InsecureRequestWarning)

        self.session = http_session(
            "report2drive",
            timeout=timeout,
            tries=retries,
            backoff=backoff_factor,
            retry_methods=("GET"),
            retry_codes=(429, 500, 502, 503, 504),
        )

    def get(
        self,
        url: str,
        headers: dict | None = None,
        params: dict | None = None,
        timeout: float | None = None,
    ) -> requests.Response | None:
        """
        GET request with retry logic and error handling.

        Args:
            url (str): the URL to send the GET request to
            headers (dict): the headers to include in the request
            params (dict): the query parameters to include in the request
            timeout (float): the timeout for the request

        Returns:
            requests.Response: the response obj if the request was successful
                otherwise None
        """
        try:
            response = self.session.get(
                url,
                headers=headers,
                params=params,
                timeout=timeout or self.timeout,
                verify=self.sslverify,
            )
            response.raise_for_status()
        except RequestException:
            logger.exception(f"HTTP GET request to {url} failed.")
            return None
        except Exception:
            logger.exception(f"Unexpected error fetching {url}.")
            return None

        return response


def get_quarter_boundaries(quarter_offset: int) -> Tuple[datetime, datetime]:
    """
    It computes the start and end datetime of the quarter.
    `quarter_offset` is used to select the quarter to report for, expressed as
    an offset (in quarters) from the current one.

    Args:
        quarter_offset (int): the quarter offset from the current one, e.g. 1

    Returns:
        Tuple[datetime, datetime]: the start and end datetime of the quarter
    """

    now = datetime.now(timezone.utc)
    logger.debug(f"Current datetime: {now}")

    fystart = (
        datetime(now.year - 1, 7, 1, tzinfo=timezone.utc)
        if now.month in range(1, 7)
        else datetime(now.year, 7, 1)
    )
    logger.debug("Fiscal year start datetime: {}".format(fystart))

    quarters = {}
    for i in range(1, 5):
        quarters.setdefault(i, []).append(
            (fystart + relativedelta(months=3 * (i - 1))).replace(second=0)
        )
        quarters[i].append(
            ((fystart + relativedelta(months=3 * (i))) - relativedelta(days=1))
            .replace(hour=23)
            .replace(minute=59)
            .replace(second=59)
        )

    cur_quarter = -1
    for q, b in quarters.items():
        if b[0] <= now <= b[1]:
            cur_quarter = q
    logger.debug("Current quarter: {}".format(cur_quarter))

    return (
        quarters[cur_quarter][0] - relativedelta(months=3 * (quarter_offset)),
        quarters[cur_quarter][1] - relativedelta(months=3 * (quarter_offset)),
    )


def get_slos(
    config: configparser.ConfigParser, vfrom: datetime, http_client: HTTPClient
) -> dict:
    """
    Gets the list of SLOs to report for, by querying Prometheus with the query

    Args:
        config (configparser): the config object, used to get the Prometheus
            endpoint and the query to get the SLOs to report for.
        vfrom (datetime): the start datetime of the report, used as a parameter
            to identify the SLOs to include in the report.

    Returns:
        dict: a dictionary mapping each service to the list of SLOs to include
        in the report
    """
    slos_per_service = {}

    query = config.get("prometheus", "slos_query", fallback=None)
    if query is None:
        raise ValueError(
            "slos_query is required in the prometheus section of the config file"  # noqa E501
        )
    logger.debug(
        f"Querying Prometheus for SLOs with query: {query} and time: {vfrom}"
    )

    response = http_client.get(
        "{}/api/v1/query".format(
            config.get(
                "prometheus",
                "hostname",
                fallback="https://thanos-query.discovery.wmnet",
            )
        ),
        params={
            "query": query,
            "time": vfrom.strftime("%Y-%m-%dT%H:%M:%SZ"),
        },
    )

    if response:
        raw = response.json()
        if raw["status"] == "success":
            if raw["data"]["resultType"] == "vector":
                for result in raw["data"]["result"]:
                    slo_name = result["metric"]["sloth_service"]
                    slos_per_service.setdefault(slo_name, []).append(
                        result["metric"]["sloth_slo"]
                    )

    return slos_per_service


def download_report(
    config: configparser.ConfigParser,
    vservice: str,
    vslo: str,
    vfrom: datetime,
    vto: datetime,
    http_client: HTTPClient,
) -> BytesIO | None:
    """
    Downloads the report for the given service/slo and time range from Grafana.
    Grafana endpoint and dashboardreporter-app additional settings are read
    from the config file.
    Moreover, report variable defaults are read from the config file and added
    to the parameters, with the "var-" prefix.

    Args:
        config (configparser): the config object, used to get the Grafana
            endpoint, dashboardreporter-app additional settings,
            and report variable defaults.
        vservice (str): the service name, used as a parameter to filter the
            report
        vslo (str): the slo name, used as a parameter to filter the report
        vfrom (datetime): the start datetime of the report
        vfrom (datetime): the end datetime of the report

    Returns:
        BytesIO: the report content as a BytesIO buffer
        None: if error occurs during the download
    """
    params = {
        "from": vfrom.strftime("%Y-%m-%dT%H:%M:%S.")
        + f"{vfrom.microsecond // 1000:03d}Z",
        "to": vto.strftime("%Y-%m-%dT%H:%M:%S.")
        + f"{vto.microsecond // 1000:03d}Z",
        "var-service": vservice,
        "var-slo": vslo,
    }

    # params validation
    dashUid = config.get(
        "dashboardreporter-app-settings", "dashUid", fallback=None
    )
    if dashUid is None:
        raise ValueError(
            "dashUid is required in the dashboardreporter-app-settings section of the config file"  # noqa E501
        )
    params |= config["dashboardreporter-app-settings"]

    if config.has_section("report-var-defaults"):
        report_var_defaults = {
            f"var-{k}": v for k, v in config["report-var-defaults"].items()
        }
        params |= report_var_defaults

    headers = {}
    grafana_token = config.get("grafana", "bearer_token", fallback=None)
    if grafana_token:
        headers |= {"Authorization": "Bearer {}".format(grafana_token)}

    endpoint = "{}/{}".format(
        config.get("grafana", "hostname", fallback="http://localhost:3000"),
        config.get(
            "grafana",
            "api",
            fallback="api/plugins/mahendrapaipuri-dashboardreporter-app/resources/report",  # noqa E501
        ),
    )

    response = http_client.get(
        endpoint, headers=headers, params=params, timeout=300
    )
    if response is None:
        return None

    return BytesIO(response.content)


def get_credentials(
    config: configparser.ConfigParser,
) -> service_account.Credentials:
    """
    Get Google Drive API credentials using the service account key file.

    Args:
        config (configparser): the config object, used to get the path to the
            service account key file

    Returns:
        service_account.Credentials: the credentials object to use with the
            Google service client
    """
    SCOPES = ["https://www.googleapis.com/auth/drive"]
    return service_account.Credentials.from_service_account_file(
        config["drive"]["key_file"],
        scopes=SCOPES,
    )


def upload_report(
    config: configparser.ConfigParser,
    service: str,
    slo: str,
    vfrom: datetime,
    vto: datetime,
    buf: BytesIO,
) -> str | None:
    """
    Uploads the report to Google Drive, in the folder specified in the config
    file.

    Args:
        config (configparser): the config object, used to
            * get the Google Drive API credentials
            * get the upload folder id
        service (str): the service name, used to build the report filename
        slo (str): the slo name, used to build the report filename
        vfrom (datetime): the start datetime of the report, used to build the
            report filename
        vto (datetime): the end datetime of the report, used to build the
            report filename
        buf (BytesIO): the report content as a BytesIO buffer

    Returns:
        (str) id of the uploaded file in Google Drive
    """

    gservice = build(
        "drive",
        "v3",
        credentials=get_credentials(config),
        cache_discovery=False,
    )

    filename = "{}_{}_{}_{}.pdf".format(
        service, slo, vfrom.strftime("%Y%m%d"), vto.strftime("%Y%m%d")
    )
    folder_id = config["drive"]["upload_folder_id"]
    media = MediaIoBaseUpload(buf, mimetype="application/pdf")

    files = []
    try:
        query = (
            f"name = '{filename}' "
            f"and '{folder_id}' in parents "
            f"and trashed = false"
        )

        res = (
            gservice.files()
            .list(
                q=query,
                fields="files(id,name)",
                supportsAllDrives=True,
                includeItemsFromAllDrives=True,
            )
            .execute(num_retries=config.getint("http", "retries", fallback=3))
        )
        files = res.get("files", [])

    except GoogleAuthError as e:
        logger.exception(f"Authentication error: {service}/{slo}.")
        raise e  # Considered non-retriable, re-raise to stop execution
    except HttpError as e:
        if e.resp.status == 401:
            logger.exception(f"Authorization error: {service}/{slo}.")
            raise e  # Considered non-retriable, re-raise to stop execution
        logger.exception(
            f"Http error while checking for existing files: {service}/{slo}."
        )
        return None
    except Exception:
        logger.exception(
            f"Unexpected error while checking for existing files: {service}/{slo}."
        )
        return None

    try:
        if files:
            logger.debug("File with the same name already exists, updating it")
            file = (
                gservice.files()
                .update(
                    fileId=files[0]["id"],
                    media_body=media,
                    supportsAllDrives=True,
                )
                .execute(
                    num_retries=config.getint("http", "retries", fallback=3)
                )
            )
        else:
            logger.debug("No existing file found, creating a new one")
            file_metadata = {
                "name": filename,
                "parents": [folder_id],
            }

            file = (
                gservice.files()
                .create(
                    body=file_metadata,
                    media_body=media,
                    fields="id",
                    supportsAllDrives=True,
                )
                .execute(
                    num_retries=config.getint("http", "retries", fallback=3)
                )
            )
    except GoogleAuthError as e:
        logger.exception(f"Authentication error: {service}/{slo}.")
        raise e  # Considered non-retriable, re-raise to stop execution
    except HttpError as e:
        if e.resp.status == 401:
            logger.exception(f"Authorization error: {service}/{slo}.")
            raise e  # Considered non-retriable, re-raise to stop execution
        logger.exception(
            f"Http error while uploading report: {service}/{slo}."
        )
        return None
    except Exception:
        logger.exception(f"Failed to upload report for {service}/{slo}.")
        return None

    return file["id"]


@click.command()
@click.option(
    "--offset",
    default=1,
    help="Offset (expressed in quarters from current) to report for",
)
@click.option(
    "--config-file",
    type=click.Path(exists=True, dir_okay=False),
    default="report2drive.ini",
    show_default=True,
    help="Path to configuration file",
)
@click.option(
    "--debug",
    is_flag=True,
    default=False,
    help="Enable debug logging",
)
def main(offset: int, config_file: str, debug: bool) -> int:
    """
    Main function to orchestrate the report download and upload.
    """
    logger.setLevel(logging.DEBUG if debug else logging.INFO)

    config = configparser.ConfigParser()
    config.optionxform = str  # pyright: ignore[reportAttributeAccessIssue]
    config.read(config_file)

    http_client = HTTPClient(
        retries=config.getint("http", "retries", fallback=3),
        backoff_factor=2.0,
        timeout=300.0,
        sslverify=config.getboolean("http", "sslverify", fallback=True),
    )

    start, end = get_quarter_boundaries(offset)
    logger.debug(
        "generating report for time range: {} - {}".format(start, end)
    )

    slos_per_service = get_slos(config, start, http_client)
    if not slos_per_service:
        logger.error("No SLOs found to report for, exiting")
        return 1

    missing_reports = 0
    failed_uploads = 0
    for svc, slos in slos_per_service.items():
        for slo in slos:
            logger.debug(f"Processing report for {svc}/{slo}")
            report_buf = download_report(
                config, svc, slo, start, end, http_client
            )

            if report_buf is None:
                logger.error(f"Failed to download report for {svc}/{slo}")
                missing_reports += 1
                continue

            logger.debug(
                f"Report for {svc}/{slo} downloaded successfully, size: {report_buf.getbuffer().nbytes} bytes"  # noqa E501
            )
            upload_id = upload_report(
                config,
                svc,
                slo,
                start,
                end,
                report_buf,
            )

            if upload_id is None:
                failed_uploads += 1
                logger.error(f"Failed to upload report for {svc}/{slo}")
                continue

            logger.info(f"Uploaded {upload_id} for {svc}/{slo}")

    if missing_reports > 0:
        return 2

    if failed_uploads > 0:
        return 3

    return 0


if __name__ == "__main__":
    sys.exit(main())
