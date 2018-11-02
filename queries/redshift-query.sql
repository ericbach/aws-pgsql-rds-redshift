create table if not exists transaction(
  Id integer not null,
  MemberId integer not null,
  RewardAmount decimal(5,2) not null,
  DiscountAmount decimal(5,2) not null,
  TransactionDateTime timestamp not null,
  CreatedBy varchar(25),
  CreatedDate timestamp not null,
  ModifiedBy varchar(25),
  ModifiedDate timestamp not null,
  MemberNumber varchar(16) not null
);

copy transaction
from 's3://rds-redshift-copy-logsbucket-ck593kumasji/loyalty_1541100811349.json'
iam_role 'arn:aws:iam::434058760900:role/eb-Redshift-service-role'
--format as json 's3://eric-bach-stuff/jsonpaths.json'
format as json 'auto'
region 'us-west-2';

--drop table if exists transaction;
--select * from transaction

rollback;
select * from stl_load_errors;