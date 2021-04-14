import boto3
import logging
import os

events = boto3.client('events')
logger = logging.getLogger()
logger.setLevel(logging.INFO)

C_OPERATOR = os.environ.get("OPERATOR")
C_KEY = os.environ.get("KEY")
C_VALUE = os.environ.get("VALUE")


def lambda_handler(event=None, Contect=None):
    print(event['detail'])
    source = event['detail']['eventSource']
    event_name = event['detail']['eventName']
    if event_name == "PutBucketPolicy" and source == "s3.amazonaws.com":
        s3_main(event['detail'])


def s3_main(event):
    bucket_policy = event['requestParameters']['bucketPolicy']
    bucket_name = event['requestParameters']['bucketName']

    delete = policy_validity(bucket_policy['Statement'])

    if delete is False:
        logger.info(f"Bucket policy for {bucket_name} is valid - no action required")
        return
    logger.info(f"Bucket policy for {bucket_name} is invalid - policy will be deleted")

    s3 = boto3.client('s3')
    try:
        s3.delete_bucket_policy(Bucket=bucket_name)
        logger.info("Bucket policy deleted")
    except Exception as e:
        logger.error(f"Failed to delete bucket policy, {e}")


# Return True if policy does not satisfy condition, otherwise False
def policy_validity(statements):
    for statement in statements:
        if "Condition" not in statement:
            return True
        if C_OPERATOR not in statement['Condition']:
            return True
        if C_KEY not in statement['Condition'][C_OPERATOR]:
            return True
        # This can be string or list of strings, either will work
        if C_VALUE not in statement['Condition'][C_OPERATOR][C_KEY]:
            return True
        # Possible enhancement to check for list of values
    return False
