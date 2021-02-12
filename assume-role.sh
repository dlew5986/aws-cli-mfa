#!/bin/bash

#
# adapted from:
# https://github.com/neillturner/assume-aws-role-mfa
#

# positional command-line arguments
source_profile=${1}                    # required: name of the source profile; should be the name of the IAM user
source_profile_mfa_arn=${2}            # required: aws arn for the mfa enabled on relevant IAM user
role_arn=${3}                          # required: aws arn for the role to be assumed
duration_seconds=${4:-14400}           # optional: duration in seconds, default value is 4 hours
aws_region=${5:-us-east-2}             # optional: name of the aws region, default value is us-east-2

# get mfa token code; interactive input
read -r -n 7 -t 30 -p "enter 6-digit mfa token code: " mfa_token_code

# get date/time stamp of the request
# in UTC (to match expiration date/time stamp provided by aws)
# and in local (to help the humans)
aws_request_utc=$(date -u +%FT%TZ)
aws_request_local=$(date +%FT%TLocal)


# get temporary session token
temp_creds=(`aws sts assume-role \
                --role-arn "$role_arn" \
                --role-session-name "placeholder" \
                --region "$aws_region" \
                --profile "$source_profile" \
                --serial-number "$source_profile_mfa_arn" \
                --token-code $mfa_token_code \
                --duration-seconds $duration_seconds \
                --query "[Credentials.AccessKeyId,Credentials.SecretAccessKey,Credentials.SessionToken,Credentials.Expiration]" \
                --output text`)

# there's got to be a better way to do this
aws_access_key_id="${temp_creds[0]}"
aws_secret_access_key="${temp_creds[1]}"
aws_session_token="${temp_creds[2]}"
aws_expiration="${temp_creds[3]}"

# set the default profile in the aws credentials and config files
aws configure set default.region $aws_region
aws configure set aws_access_key_id $aws_access_key_id
aws configure set aws_secret_access_key $aws_secret_access_key
aws configure set aws_session_token $aws_session_token

# send summary to file
echo ""                                                       | tee ~/.aws/expiration
echo "temp session token:"                                    | tee -a ~/.aws/expiration
echo ""                                                       | tee -a ~/.aws/expiration
echo "source profile       $source_profile"                   | tee -a ~/.aws/expiration
echo "requested  (local)   $aws_request_local"                | tee -a ~/.aws/expiration
echo "requested  (utc)     $aws_request_utc"                  | tee -a ~/.aws/expiration
echo "expiration (utc)     $aws_expiration"                   | tee -a ~/.aws/expiration
echo "duration             $((duration_seconds/60/60)) hours" | tee -a ~/.aws/expiration
echo ""                                                       | tee -a ~/.aws/expiration
