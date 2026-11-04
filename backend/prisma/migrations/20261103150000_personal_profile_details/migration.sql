ALTER TABLE "personal_trainers"
  ADD COLUMN "cep" VARCHAR(9),
  ADD COLUMN "city" VARCHAR(100),
  ADD COLUMN "state" CHAR(2),
  ADD COLUMN "age" SMALLINT,
  ADD COLUMN "sex" "UserSex",
  ADD COLUMN "heightCm" SMALLINT,
  ADD COLUMN "weightKg" DOUBLE PRECISION,
  ADD COLUMN "experienceLevel" "ExperienceLevel",
  ADD COLUMN "injury" TEXT,
  ADD COLUMN "healthIssues" TEXT,
  ADD COLUMN "medications" TEXT;
