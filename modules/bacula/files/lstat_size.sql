/*
SPDX-License-Identifier: Apache-2.0
*/

DELIMITER $$

CREATE FUNCTION lstat_size(p_blob TINYBLOB)
RETURNS BIGINT UNSIGNED
DETERMINISTIC
BEGIN
    DECLARE txt      TEXT;
    DECLARE field8   VARCHAR(255);
    DECLARE alphabet VARCHAR(64) DEFAULT
        'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';

    DECLARE result   BIGINT UNSIGNED DEFAULT 0;
    DECLARE i        INT DEFAULT 1;
    DECLARE ch       CHAR(1);
    DECLARE val      INT;
    DECLARE err_msg  TEXT;

    -- Convert blob to text
    SET txt = CONVERT(p_blob USING utf8mb4);

    -- Extract 8th space-separated field
    SET field8 = SUBSTRING_INDEX(SUBSTRING_INDEX(txt, ' ', 8), ' ', -1);

    -- Decode base64-integer using the provided alphabet
    WHILE i <= CHAR_LENGTH(field8) DO
        SET ch  = SUBSTRING(field8, i, 1);
        SET val = LOCATE(ch, alphabet) - 1;

        IF val < 0 THEN
            SET err_msg = CONCAT('Invalid base64 character: ', ch);
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = err_msg;
        END IF;

        SET result = result * 64 + val;
        SET i = i + 1;
    END WHILE;

    RETURN result;
END$$

DELIMITER ;
