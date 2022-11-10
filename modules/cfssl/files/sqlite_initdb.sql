-- SPDX-License-Identifier: Apache-2.0
CREATE TABLE certificates (
  serial_number            blob NOT NULL,
  authority_key_identifier blob NOT NULL,
  ca_label                 blob,
  status                   blob NOT NULL,
  reason                   int,
  expiry                   timestamp,
  revoked_at               timestamp,
  pem                      blob NOT NULL,
  issued_at                timestamp,
  not_before               timestamp,
  metadata                 text,
  sans                     text,
  common_name              text,
  PRIMARY KEY(serial_number, authority_key_identifier)
);

CREATE TABLE ocsp_responses (
  serial_number            blob NOT NULL,
  authority_key_identifier blob NOT NULL,
  body                     blob NOT NULL,
  expiry                   timestamp,
  PRIMARY KEY(serial_number, authority_key_identifier),
  FOREIGN KEY(serial_number, authority_key_identifier) REFERENCES certificates(serial_number, authority_key_identifier)
);
