SELECT * FROM "Transaction"

INSERT INTO "Transaction" ("Id", "MemberId", "RewardAmount", "DiscountAmount", "TransactionDateTime", "CreatedDate", "ModifiedDate", "MemberNumber")
VALUES (4, 1, 20.0, 0, '2018-10-20', '2018-10-20', '2018-10-20', '6202722176072009')

SELECT * FROM pg_replication_slots
SELECT * FROM pg_create_logical_replication_slot('loyalty_slot', 'test_decoding')
SELECT * FROM pg_logical_slot_get_changes('loyalty_slot', NULL, NULL)
