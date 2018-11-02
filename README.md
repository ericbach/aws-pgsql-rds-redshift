# aws-pgsql-rds-redshift

Creates a lambda to poll the pgsql replication slot for any WAL log changes every 5 minutes using a CloudWatch event. Any WAL logs created get saved to the S3 bucket as JSON.
