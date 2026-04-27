-- SECTION 7: Service User + RSA Key Secret
-- ============================================================
USE ROLE ACCOUNTADMIN;

-- Service user for SPCS JWT key-pair auth.
-- INSTRUCTOR: replace RSA_PUBLIC_KEY with the public key from your generated key pair.
CREATE USER IF NOT EXISTS COCO_SDLC_HOL_SERVICE_USER
  RSA_PUBLIC_KEY = '<PASTE_YOUR_RSA_PUBLIC_KEY_HERE>'
  DEFAULT_ROLE = ATTENDEE_ROLE
  COMMENT = 'Service user for SPCS container key-pair auth';

GRANT ROLE ATTENDEE_ROLE TO USER COCO_SDLC_HOL_SERVICE_USER;

USE ROLE ATTENDEE_ROLE;

-- Private key stored as Secret for container injection.
-- INSTRUCTOR: paste the unencrypted PEM content for COCO_SDLC_HOL_SERVICE_USER
-- between the single quotes below before running this section.
-- Generate a key pair with:
--   openssl genrsa 2048 | openssl pkcs8 -topk8 -inform PEM -out rsa_key.p8 -nocrypt
-- Then register the public key on the service user:
--   ALTER USER COCO_SDLC_HOL_SERVICE_USER SET RSA_PUBLIC_KEY='<public_key_content>';
CREATE OR REPLACE SECRET COCO_SDLC_HOL_99.PUBLIC.coco_sdlc_hol_private_key
  TYPE = GENERIC_STRING
  SECRET_STRING = '-----BEGIN PRIVATE KEY-----
<PASTE_YOUR_UNENCRYPTED_PRIVATE_KEY_HERE>
-----END PRIVATE KEY-----'
  COMMENT = 'Unencrypted RSA private key for SPCS JWT key-pair auth';

-- ============================================================
