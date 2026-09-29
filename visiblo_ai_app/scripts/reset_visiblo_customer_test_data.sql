\set ON_ERROR_STOP on

BEGIN;

CREATE TEMP TABLE resetbiz(id text PRIMARY KEY) ON COMMIT DROP;
INSERT INTO resetbiz(id) VALUES
('cmpnu87d80003rrqjzwq8ipdf'),
('cmoiksm1t0015tpgawowhevyz'),
('cmoikt8nf001ftpgac00o7w4m'),
('cmul8ur3300067zpci5ilrcfm');

CREATE TEMP TABLE resetusers(id text PRIMARY KEY) ON COMMIT DROP;
INSERT INTO resetusers(id)
SELECT id FROM "User"
WHERE lower(email) = 'visibloai@gmail.com';

CREATE TEMP TABLE resetloc(id text PRIMARY KEY) ON COMMIT DROP;
INSERT INTO resetloc(id)
SELECT id FROM "Location"
WHERE "businessId" IN (SELECT id FROM resetbiz);

CREATE TEMP TABLE resetsub(id text PRIMARY KEY) ON COMMIT DROP;
INSERT INTO resetsub(id)
SELECT id FROM "Subscription"
WHERE "businessId" IN (SELECT id FROM resetbiz)
   OR "userId" IN (SELECT id FROM resetusers);

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM "User" u
    JOIN "UserRole" r ON r."userId" = u.id
    WHERE lower(u.email) = 'solverixtech@gmail.com'
      AND r.role = 'SUPER_ADMIN'
      AND r."scopeType" = 'PLATFORM'
  ) THEN
    RAISE EXCEPTION 'Safety stop: solverixtech@gmail.com is not SUPER_ADMIN / PLATFORM.';
  END IF;
END $$;

DELETE FROM user_sessions
WHERE sess::text ILIKE '%visibloai%'
   OR sess::text ILIKE '%solverixtech%';

DELETE FROM "CouponUsage"
WHERE "businessId" IN (SELECT id FROM resetbiz)
   OR "userId" IN (SELECT id FROM resetusers)
   OR "subscriptionId" IN (SELECT id FROM resetsub);

DELETE FROM "Invoice"
WHERE "businessId" IN (SELECT id FROM resetbiz)
   OR "userId" IN (SELECT id FROM resetusers)
   OR "subscriptionId" IN (SELECT id FROM resetsub);

DELETE FROM "Payment"
WHERE "businessId" IN (SELECT id FROM resetbiz)
   OR "userId" IN (SELECT id FROM resetusers)
   OR "subscriptionId" IN (SELECT id FROM resetsub);

DELETE FROM "Subscription"
WHERE id IN (SELECT id FROM resetsub);

DELETE FROM "BusinessProduct"
WHERE "locationId" IN (SELECT id FROM resetloc);

DELETE FROM "Review"
WHERE "locationId" IN (SELECT id FROM resetloc);

DELETE FROM "LocationDailyInsight"
WHERE "locationId" IN (SELECT id FROM resetloc);

DELETE FROM "TrackedKeyword"
WHERE "locationId" IN (SELECT id FROM resetloc);

DELETE FROM "Competitor"
WHERE "locationId" IN (SELECT id FROM resetloc);

DELETE FROM "GeoGridPoint"
WHERE "locationId" IN (SELECT id FROM resetloc);

DELETE FROM "Citation"
WHERE "locationId" IN (SELECT id FROM resetloc);

DELETE FROM "SyncJob"
WHERE "businessId" IN (SELECT id FROM resetbiz)
   OR "locationId" IN (SELECT id FROM resetloc);

DELETE FROM "GbpConnection"
WHERE "clientId" IN (SELECT id FROM resetbiz);

DELETE FROM "SocialQueue"
WHERE "postId" IN (
  SELECT id FROM "SocialPost"
  WHERE "businessId" IN (SELECT id FROM resetbiz)
);

DELETE FROM "AiPlatformPost"
WHERE "businessId" IN (SELECT id FROM resetbiz);

DELETE FROM "AiContentPlanItem"
WHERE "businessId" IN (SELECT id FROM resetbiz);

DELETE FROM "AiContentPlan"
WHERE "businessId" IN (SELECT id FROM resetbiz);

DELETE FROM "AiPost"
WHERE "businessId" IN (SELECT id FROM resetbiz);

DELETE FROM "SocialPost"
WHERE "businessId" IN (SELECT id FROM resetbiz);

DELETE FROM "SocialCreative"
WHERE "businessId" IN (SELECT id FROM resetbiz);

DELETE FROM "SocialSettings"
WHERE "businessId" IN (SELECT id FROM resetbiz);

DELETE FROM "SocialAccount"
WHERE "businessId" IN (SELECT id FROM resetbiz);

DELETE FROM "Alert"
WHERE "businessId" IN (SELECT id FROM resetbiz);

DELETE FROM "AutomationConsent"
WHERE "businessId" IN (SELECT id FROM resetbiz)
   OR "userId" IN (SELECT id FROM resetusers);

DELETE FROM "AiAction"
WHERE "businessId" IN (SELECT id FROM resetbiz)
   OR "userId" IN (SELECT id FROM resetusers);

DELETE FROM "Location"
WHERE id IN (SELECT id FROM resetloc);

DELETE FROM "UserRole"
WHERE "businessId" IN (SELECT id FROM resetbiz)
   OR "userId" IN (SELECT id FROM resetusers);

DELETE FROM "_BusinessUsers"
WHERE "A" IN (SELECT id FROM resetbiz)
   OR "B" IN (SELECT id FROM resetusers);

DELETE FROM "OtpVerification"
WHERE lower(email) = 'visibloai@gmail.com';

DELETE FROM "DeviceToken"
WHERE "userId" IN (SELECT id FROM resetusers);

DELETE FROM "LoginHistory"
WHERE "userId" IN (SELECT id FROM resetusers);

DELETE FROM "Business"
WHERE id IN (SELECT id FROM resetbiz);

DELETE FROM "User"
WHERE id IN (SELECT id FROM resetusers);

COMMIT;

SELECT
  u.email,
  r.role,
  r."scopeType",
  r."businessId"
FROM "User" u
LEFT JOIN "UserRole" r ON r."userId" = u.id
WHERE lower(u.email) IN ('visibloai@gmail.com', 'solverixtech@gmail.com')
ORDER BY u.email, r."scopeType", r.role;
