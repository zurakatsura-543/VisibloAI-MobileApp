\set ON_ERROR_STOP on

-- Removes only the VisibloAI onboarding test account. It never uses hard-coded
-- business IDs and aborts if its business belongs to another user.
BEGIN;

CREATE TEMP TABLE reset_users(id text PRIMARY KEY) ON COMMIT DROP;
INSERT INTO reset_users(id)
SELECT id
FROM "User"
WHERE lower(email) = 'visibloai@gmail.com';

CREATE TEMP TABLE reset_businesses(id text PRIMARY KEY) ON COMMIT DROP;
INSERT INTO reset_businesses(id)
SELECT DISTINCT "businessId"
FROM "UserRole"
WHERE "userId" IN (SELECT id FROM reset_users)
  AND "businessId" IS NOT NULL;

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM reset_users) THEN
    RAISE EXCEPTION 'Safety stop: visibloai@gmail.com was not found.';
  END IF;

  IF EXISTS (
    SELECT 1
    FROM "UserRole" r
    WHERE r."businessId" IN (SELECT id FROM reset_businesses)
      AND r."userId" NOT IN (SELECT id FROM reset_users)
  ) THEN
    RAISE EXCEPTION 'Safety stop: a target business is shared with another user.';
  END IF;
END $$;

CREATE TEMP TABLE reset_locations(id text PRIMARY KEY) ON COMMIT DROP;
INSERT INTO reset_locations(id)
SELECT id FROM "Location"
WHERE "businessId" IN (SELECT id FROM reset_businesses);

CREATE TEMP TABLE reset_subscriptions(id text PRIMARY KEY) ON COMMIT DROP;
INSERT INTO reset_subscriptions(id)
SELECT id FROM "Subscription"
WHERE "userId" IN (SELECT id FROM reset_users)
   OR "businessId" IN (SELECT id FROM reset_businesses);

DELETE FROM user_sessions
WHERE sess::text ILIKE '%visibloai@gmail.com%';

DELETE FROM "CouponUsage"
WHERE "userId" IN (SELECT id FROM reset_users)
   OR "businessId" IN (SELECT id FROM reset_businesses)
   OR "subscriptionId" IN (SELECT id FROM reset_subscriptions);

DELETE FROM "Invoice"
WHERE "userId" IN (SELECT id FROM reset_users)
   OR "businessId" IN (SELECT id FROM reset_businesses)
   OR "subscriptionId" IN (SELECT id FROM reset_subscriptions);

DELETE FROM "Payment"
WHERE "userId" IN (SELECT id FROM reset_users)
   OR "businessId" IN (SELECT id FROM reset_businesses)
   OR "subscriptionId" IN (SELECT id FROM reset_subscriptions);

DELETE FROM "Subscription" WHERE id IN (SELECT id FROM reset_subscriptions);

DELETE FROM "BusinessProduct" WHERE "locationId" IN (SELECT id FROM reset_locations);
DELETE FROM "Review" WHERE "locationId" IN (SELECT id FROM reset_locations);
DELETE FROM "LocationDailyInsight" WHERE "locationId" IN (SELECT id FROM reset_locations);
DELETE FROM "TrackedKeyword" WHERE "locationId" IN (SELECT id FROM reset_locations);
DELETE FROM "Competitor" WHERE "locationId" IN (SELECT id FROM reset_locations);
DELETE FROM "GeoGridPoint" WHERE "locationId" IN (SELECT id FROM reset_locations);
DELETE FROM "Citation" WHERE "locationId" IN (SELECT id FROM reset_locations);
DELETE FROM "SyncJob"
WHERE "businessId" IN (SELECT id FROM reset_businesses)
   OR "locationId" IN (SELECT id FROM reset_locations);

DELETE FROM "GbpConnection" WHERE "clientId" IN (SELECT id FROM reset_businesses);

DELETE FROM "SocialQueue"
WHERE "postId" IN (
  SELECT id FROM "SocialPost" WHERE "businessId" IN (SELECT id FROM reset_businesses)
);

DELETE FROM "AiPlatformPost" WHERE "businessId" IN (SELECT id FROM reset_businesses);
DELETE FROM "AiContentPlanItem" WHERE "businessId" IN (SELECT id FROM reset_businesses);
DELETE FROM "AiContentPlan" WHERE "businessId" IN (SELECT id FROM reset_businesses);
DELETE FROM "AiPost" WHERE "businessId" IN (SELECT id FROM reset_businesses);
DELETE FROM "AiCostLog" WHERE "businessId" IN (SELECT id FROM reset_businesses);
DELETE FROM "SocialPost" WHERE "businessId" IN (SELECT id FROM reset_businesses);
DELETE FROM "SocialCreative" WHERE "businessId" IN (SELECT id FROM reset_businesses);
DELETE FROM "SocialSettings" WHERE "businessId" IN (SELECT id FROM reset_businesses);
DELETE FROM "SocialAccount" WHERE "businessId" IN (SELECT id FROM reset_businesses);
DELETE FROM "Alert" WHERE "businessId" IN (SELECT id FROM reset_businesses);
DELETE FROM "AutomationConsent"
WHERE "businessId" IN (SELECT id FROM reset_businesses)
   OR "userId" IN (SELECT id FROM reset_users);
DELETE FROM "AiAction"
WHERE "businessId" IN (SELECT id FROM reset_businesses)
   OR "userId" IN (SELECT id FROM reset_users);

DELETE FROM "Location" WHERE id IN (SELECT id FROM reset_locations);
DELETE FROM "UserRole"
WHERE "businessId" IN (SELECT id FROM reset_businesses)
   OR "userId" IN (SELECT id FROM reset_users);
DELETE FROM "_BusinessUsers"
WHERE "A" IN (SELECT id FROM reset_businesses)
   OR "B" IN (SELECT id FROM reset_users);
DELETE FROM "OtpVerification" WHERE lower(email) = 'visibloai@gmail.com';
DELETE FROM "DeviceToken" WHERE "userId" IN (SELECT id FROM reset_users);
DELETE FROM "LoginHistory" WHERE "userId" IN (SELECT id FROM reset_users);
DELETE FROM "Business" WHERE id IN (SELECT id FROM reset_businesses);
DELETE FROM "User" WHERE id IN (SELECT id FROM reset_users);

COMMIT;

SELECT 'VisibloAI onboarding test account deleted.' AS result;
