-- AlterEnum
ALTER TYPE "Provider" ADD VALUE 'PLAID';

-- AlterTable
ALTER TABLE "ConnectedAccount" ADD COLUMN     "plaid_account_id" TEXT,
ADD COLUMN     "plaid_item_id" UUID;

-- CreateTable
CREATE TABLE "PlaidItem" (
    "id" UUID NOT NULL,
    "user_id" UUID NOT NULL,
    "item_id" TEXT NOT NULL,
    "access_token_ciphertext" TEXT NOT NULL,
    "cursor" TEXT,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "PlaidItem_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "PlaidItem_item_id_key" ON "PlaidItem"("item_id");

-- CreateIndex
CREATE INDEX "PlaidItem_user_id_idx" ON "PlaidItem"("user_id");

-- AddForeignKey
ALTER TABLE "PlaidItem" ADD CONSTRAINT "PlaidItem_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "User"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "ConnectedAccount" ADD CONSTRAINT "ConnectedAccount_plaid_item_id_fkey" FOREIGN KEY ("plaid_item_id") REFERENCES "PlaidItem"("id") ON DELETE SET NULL ON UPDATE CASCADE;
