-- ============================================================
-- COCO SDLC HOL — SPCS Deployment Setup Script
-- Run this in a Snowflake worksheet (ACCOUNTADMIN role required for step 1)
-- All other steps use SYSADMIN
-- ============================================================
--
-- FULL DEPLOYMENT WORKFLOW:
-- 1. Build image:  docker build --platform linux/amd64 -t coco-portal:latest .
-- 2. Login to registry: snow spcs image-registry login --connection ennovate
-- 3. Get repo URL: run SHOW IMAGE REPOSITORIES in step 3 below
-- 4. Tag image: docker tag coco-portal:latest <REPO_URL>/coco-portal:latest
-- 5. Push image: docker push <REPO_URL>/coco-portal:latest
-- 6. Run this script (steps 1-6 in order)
-- 7. Get endpoint URL from SHOW ENDPOINTS in step 6
-- ============================================================

USE ROLE ACCOUNTADMIN;
USE DATABASE COCO_SDLC_HOL;
USE SCHEMA PUBLIC;


-- ============================================================
-- STEP 1: Grant BIND SERVICE ENDPOINT (requires ACCOUNTADMIN)
-- ============================================================
-- Required once per account role to allow public HTTPS endpoint creation.
-- Without this, CREATE SERVICE with public: true will fail with a privilege error.
GRANT BIND SERVICE ENDPOINT ON ACCOUNT TO ROLE SYSADMIN;


-- ============================================================
-- STEP 2: Create Snowflake Secret for private key (switch to SYSADMIN)
-- ============================================================
USE ROLE SYSADMIN;

-- Store the unencrypted RSA private key PEM content as a Snowflake Secret.
-- Replace the placeholder below with the actual PEM content from your key file.
-- Do NOT include SNOWFLAKE_PRIVATE_KEY_PATH in the service spec — containers
-- have no external filesystem access. Use content injection via this secret.
--
-- IMPORTANT: secretKeyRef in the service spec MUST be 'secret_string' (not 'password')
-- for TYPE = GENERIC_STRING secrets.
CREATE OR REPLACE SECRET coco_sdlc_hol_private_key
  TYPE = GENERIC_STRING
  SECRET_STRING = '-----BEGIN PRIVATE KEY-----
<PASTE YOUR UNENCRYPTED PEM KEY CONTENT HERE>
-----END PRIVATE KEY-----'
  COMMENT = 'Unencrypted RSA private key for SPCS JWT key-pair auth';


-- ============================================================
-- STEP 3: Create image repository
-- ============================================================
-- Snowflake-hosted OCI registry. SPCS cannot pull from external registries (e.g., Docker Hub).
-- After creation, run SHOW IMAGE REPOSITORIES to get the repository_url for docker tag/push.
CREATE IMAGE REPOSITORY IF NOT EXISTS coco_sdlc_hol_repo;

-- Note the repository_url value from this output — you need it for docker tag and push.
SHOW IMAGE REPOSITORIES IN SCHEMA COCO_SDLC_HOL.PUBLIC;


-- ============================================================
-- STEP 4: Create compute pool
-- ============================================================
-- STANDARD_1 = 1 vCPU, ~4 GB RAM. Appropriate for this HOL demo.
-- If STANDARD_1 fails with an invalid instance family error, use CPU_X64_XS as fallback.
-- Compute pool takes 2-5 minutes to reach ACTIVE/IDLE state after creation.
-- Run SHOW COMPUTE POOLS before proceeding to CREATE SERVICE.
CREATE COMPUTE POOL IF NOT EXISTS coco_sdlc_hol_compute_pool
  MIN_NODES = 1
  MAX_NODES = 1
  INSTANCE_FAMILY = STANDARD_1
  AUTO_RESUME = TRUE
  AUTO_SUSPEND_SECS = 3600
  COMMENT = 'COCO SDLC HOL portal compute pool';

-- Wait for state = ACTIVE or IDLE before running CREATE SERVICE below.
-- Provisioning typically takes 2-5 minutes.
SHOW COMPUTE POOLS LIKE 'COCO_SDLC_HOL_COMPUTE_POOL';


-- ============================================================
-- STEP 5: Create service with inline spec
-- ============================================================
-- Replace <SNOWFLAKE_ACCOUNT> and <SNOWFLAKE_USER> with your actual values.
-- Replace <REPO_URL> with the repository_url from SHOW IMAGE REPOSITORIES above.
-- Example repo URL format: orgname-acctname.registry.snowflakecomputing.com/coco_sdlc_hol/public/coco_sdlc_hol_repo
CREATE OR REPLACE SERVICE coco_sdlc_hol_service
  IN COMPUTE POOL coco_sdlc_hol_compute_pool
  FROM SPECIFICATION $$
  spec:
    containers:
    - name: portal
      image: <REPO_URL>/coco-portal:latest
      env:
        SNOWFLAKE_ACCOUNT: "<SNOWFLAKE_ACCOUNT>"
        SNOWFLAKE_USER: "<SNOWFLAKE_USER>"
        SNOWFLAKE_WAREHOUSE: "COMPUTE_WH"
        SNOWFLAKE_DATABASE: "COCO_SDLC_HOL"
        SNOWFLAKE_SCHEMA: "MARTS"
        SNOWFLAKE_ROLE: "SYSADMIN"
        CORTEX_AGENT_NAME: "PAYMENT_ANALYTICS_AGENT"
        PORT: "3000"
        HOSTNAME: "0.0.0.0"
      secrets:
      - snowflakeSecret:
          objectName: coco_sdlc_hol_private_key
        envVarName: SNOWFLAKE_PRIVATE_KEY
        secretKeyRef: secret_string
      readinessProbe:
        port: 3000
        path: /api/health
    endpoints:
    - name: portal-endpoint
      port: 3000
      public: true
      protocol: HTTP
  $$
  MIN_INSTANCES = 1
  MAX_INSTANCES = 1;


-- ============================================================
-- STEP 6: Retrieve public endpoint URL
-- ============================================================
-- Run after the service reaches RUNNING state (check with SHOW SERVICES).
-- The ingress_url column contains the public HTTPS endpoint for the portal.
SHOW ENDPOINTS IN SERVICE coco_sdlc_hol_service;

-- Check service status / container logs if something goes wrong:
-- SHOW SERVICES LIKE 'COCO_SDLC_HOL_SERVICE';
-- CALL SYSTEM$GET_SERVICE_LOGS('COCO_SDLC_HOL.PUBLIC.COCO_SDLC_HOL_SERVICE', '0', 'portal', 100);
