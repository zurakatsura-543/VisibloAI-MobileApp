\set ON_ERROR_STOP on

-- Deletes only the two explicitly named test accounts and their businesses.
-- The transaction stops before deleting anything when a business is shared.
BEGIN;

CREATE TEMP TABLE target_users (id text PRIMARY KEY) ON COMMIT DROP;
INSERT INTO target_users (id)
SELECT id
FROM "User"
WHERE lower(email) IN (
  'aimbeatweb@gmail.com',
  'solverixtechnologies@gmail.com'
);

CREATE TEMP TABLE target_businesses (id text PRIMARY KEY) ON COMMIT DROP;
INSERT INTO target_businesses (id)
SELECT DISTINCT "businessId"
FROM "UserRole"
WHERE "userId" IN (SELECT id FROM target_users)
  AND "businessId" IS NOT NULL;

INSERT INTO target_businesses (id)
SELECT DISTINCT "A"
FROM "_BusinessUsers"
WHERE "B" IN (SELECT id FROM target_users)
ON CONFLICT DO NOTHING;

DO $$
BEGIN
  IF (SELECT COUNT(*) FROM target_users) <> 2 THEN
    RAISE EXCEPTION 'Safety stop: expected exactly two target user accounts.';
  END IF;

  IF EXISTS (
    SELECT 1 FROM "UserRole"
    WHERE "businessId" IN (SELECT id FROM target_businesses)
      AND "userId" NOT IN (SELECT id FROM target_users)
  ) OR EXISTS (
    SELECT 1 FROM "_BusinessUsers"
    WHERE "A" IN (SELECT id FROM target_businesses)
      AND "B" NOT IN (SELECT id FROM target_users)
  ) THEN
    RAISE EXCEPTION 'Safety stop: a target business is shared with another user.';
  END IF;
END $$;

CREATE TEMP TABLE target_locations (id text PRIMARY KEY) ON COMMIT DROP;
INSERT INTO target_locations (id)
SELECT id FROM "Location"
WHERE "businessId" IN (SELECT id FROM target_businesses);

CREATE TEMP TABLE target_subscriptions (id text PRIMARY KEY) ON COMMIT DROP;
INSERT INTO target_subscriptions (id)
SELECT id FROM "Subscription"
WHERE "userId" IN (SELECT id FROM target_users)
   OR "businessId" IN (SELECT id FROM target_businesses);

DELETE FROM user_sessions
WHERE sess::text ILIKE '%aimbeatweb@gmail.com%'
   OR sess::text ILIKE '%solverixtechnologies@gmail.com%';

DELETE FROM "CouponUsage"
WHERE "userId" IN (SELECT id FROM target_users)
   OR "businessId" IN (SELECT id FROM target_businesses)
   OR "subscriptionId" IN (SELECT id FROM target_subscriptions);
DELETE FROM "Invoice"
WHERE "userId" IN (SELECT id FROM target_users)
   OR "businessId" IN (SELECT id FROM target_businesses)
   OR "subscriptionId" IN (SELECT id FROM target_subscriptions);
DELETE FROM "Payment"
WHERE "userId" IN (SELECT id FROM target_users)
   OR "businessId" IN (SELECT id FROM target_businesses)
   OR "subscriptionId" IN (SELECT id FROM target_subscriptions);
DELETE FROM "Subscription" WHERE id IN (SELECT id FROM target_subscriptions);

DELETE FROM "BusinessProduct" WHERE "locationId" IN (SELECT id FROM target_locations);
DELETE FROM "Review" WHERE "locationId" IN (SELECT id FROM target_locations);
DELETE FROM "LocationDailyInsight" WHERE "locationId" IN (SELECT id FROM target_locations);
DELETE FROM "TrackedKeyword" WHERE "locationId" IN (SELECT id FROM target_locations);
DELETE FROM "Competitor" WHERE "locationId" IN (SELECT id FROM target_locations);
DELETE FROM "GeoGridPoint" WHERE "locationId" IN (SELECT id FROM target_locations);
DELETE FROM "Citation" WHERE "locationId" IN (SELECT id FROM target_locations);
DELETE FROM "SyncJob"
WHERE "businessId" IN (SELECT id FROM target_businesses)
   OR "locationId" IN (SELECT id FROM target_locations);
DELETE FROM "GbpConnection" WHERE "clientId" IN (SELECT id FROM target_businesses);

DELETE FROM "SocialQueue"
WHERE "postId" IN (
  SELECT id FROM "SocialPost" WHERE "businessId" IN (SELECT id FROM target_businesses)
);
DELETE FROM "AiPlatformPost" WHERE "businessId" IN (SELECT id FROM target_businesses);
DELETE FROM "AiContentPlanItem" WHERE "businessId" IN (SELECT id FROM target_businesses);
DELETE FROM "AiContentPlan" WHERE "businessId" IN (SELECT id FROM target_businesses);
DELETE FROM "AiPost" WHERE "businessId" IN (SELECT id FROM target_businesses);
DELETE FROM "AiCostLog" WHERE "businessId" IN (SELECT id FROM target_businesses);
DELETE FROM "SocialPost" WHERE "businessId" IN (SELECT id FROM target_businesses);
DELETE FROM "SocialCreative" WHERE "businessId" IN (SELECT id FROM target_businesses);
DELETE FROM "SocialSettings" WHERE "businessId" IN (SELECT id FROM target_businesses);
DELETE FROM "SocialAccount" WHERE "businessId" IN (SELECT id FROM target_businesses);
DELETE FROM "Alert" WHERE "businessId" IN (SELECT id FROM target_businesses);
DELETE FROM "AutomationConsent"
WHERE "businessId" IN (SELECT id FROM target_businesses)
   OR "userId" IN (SELECT id FROM target_users);
DELETE FROM "AiAction"
WHERE "businessId" IN (SELECT id FROM target_businesses)
   OR "userId" IN (SELECT id FROM target_users);

DELETE FROM "Location" WHERE id IN (SELECT id FROM target_locations);
DELETE FROM "UserRole"
WHERE "businessId" IN (SELECT id FROM target_businesses)
   OR "userId" IN (SELECT id FROM target_users);
DELETE FROM "_BusinessUsers"
WHERE "A" IN (SELECT id FROM target_businesses)
   OR "B" IN (SELECT id FROM target_users);
DELETE FROM "OtpVerification"
WHERE lower(email) IN ('aimbeatweb@gmail.com', 'solverixtechnologies@gmail.com');
DELETE FROM "DeviceToken" WHERE "userId" IN (SELECT id FROM target_users);
DELETE FROM "LoginHistory" WHERE "userId" IN (SELECT id FROM target_users);
DELETE FROM "Business" WHERE id IN (SELECT id FROM target_businesses);
DELETE FROM "User" WHERE id IN (SELECT id FROM target_users);

COMMIT;

SELECT 'Aimbeat and Solverix test users and businesses deleted.' AS result;
