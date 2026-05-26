-- Add avatar and hidePhone fields to users table
ALTER TABLE "users" ADD COLUMN IF NOT EXISTS "avatar_path" TEXT;
ALTER TABLE "users" ADD COLUMN IF NOT EXISTS "hide_phone" BOOLEAN NOT NULL DEFAULT false;