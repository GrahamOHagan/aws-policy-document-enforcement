import boto3
import json
import logging
import os

events = boto3.client('events')
logger = logging.getLogger()
logger.setLevel(logging.INFO)

C_OPERATOR = os.environ.get("OPERATOR")
C_KEY = os.environ.get("KEY")
C_VALUE = os.environ.get("VALUE")


def lambda_handler(event=None, Contect=None):
    # print(event['detail'])
    source = event['detail']['eventSource']
    event_name = event['detail']['eventName']
    if event_name == "PutBucketPolicy" and source == "s3.amazonaws.com":
        s3_main(event['detail'])
        return
    if event_name in "CreatePolicyVersion" and source == "iam.amazonaws.com":
        # Should work for CreatePolicy and CreatePolicyVersion
        if "errorCode" in event['detail']:
            code = event['detail']['errorCode']
            message = event['detail']['errorMessage']
            logger.warning(f"Policy not updated - {code} {message}")
            return
        iam_main(event['detail'], event_name)
        return
    # Handle inline policies
    logger.warning(f"Unrecognised event: {event_name} - {source}")


def s3_main(event):
    try:
        bucket_policy = event['requestParameters']['bucketPolicy']
        bucket_name = event['requestParameters']['bucketName']
    except Exception as e:
        logger.error(f"Failed to parse event, {e}")
        return

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


def iam_main(event, eventName):
    try:
        policy = json.loads(event['requestParameters']['policyDocument'])
        if "policyArn" in event['requestParameters']:
            arn = event['requestParameters']['policyArn']
            version_id = event['responseElements']['policyVersion']['versionId']
        else:
            arn = event['responseElements']['policy']['arn']
        policy_name = arn.split('/')[1]
    except Exception as e:
        logger.error(f"Failed to parse event, {e}")
        return

    delete = policy_validity(policy.get("Statement", []))

    if delete is False:
        logger.info(f"Policy {policy_name} is valid - no action required")
        return
    logger.info(f"Policy {policy_name} is invalid - policy will be deleted")

    iam = boto3.client('iam')
    try:
        if eventName == "CreatePolicyVersion":
            old_version = f"v{int(version_id[1:]) - 1}"
            # Set default version to previous version
            iam.set_default_policy_version(
                PolicyArn=arn,
                VersionId=old_version
            )
            logger.info(f"PolicyVersion {old_version} set to default")
            # Delete newly created version
            iam.delete_policy_version(
                PolicyArn=arn,
                VersionId=version_id
            )
            logger.info(f"PolicyVersion {version_id} deleted")
        else:
            iam.delete_policy(PolicyArn=arn)
            logger.info("Policy deleted")
    except Exception as e:
        logger.error(f"Failed to delete Policy/PolicyVersion, {e}")


# Return True if policy does not satisfy condition, otherwise False
def policy_validity(statements):
    for statement in statements:
        if statement['Effect'] == "Deny":
            continue # Ignore DENY statements
        if "Service" in statement['Principal']:
            continue # Ignore statements where principal is AWS Service
        if "AWS" in statement['Principal']:
            if statement['Principal']['AWS'].startswith("arn:aws:iam::cloudfront:user"):
                continue # Ignore statements where principal is a Cloudfront OAI (Legacy)
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
