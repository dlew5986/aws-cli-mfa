#!/bin/bash
#
# adapted from:
# https://github.com/neillturner/assume-aws-role-mfa
#

set -e

aws_region=us-east-2
duration_seconds=14400
profile=<PROFILE>
mfa_arn=<ARN>
mfa_profile=$profile-mfa

read -r -n 7 -t 30 -p "enter 6-digit mfa token code: " mfa_token_code

temp_creds=(`aws sts get-session-token \
                --profile "$profile" \
                --serial-number "$mfa_arn" \
                --token-code $mfa_token_code  \
                --duration-seconds $duration_seconds \
                --query "[Credentials.AccessKeyId,Credentials.SecretAccessKey,Credentials.SessionToken,Credentials.Expiration]" \
                --output text`)

aws_access_key_id="${temp_creds[0]}"
aws_secret_access_key="${temp_creds[1]}"
aws_session_token="${temp_creds[2]}"
aws_expiration="${temp_creds[3]}"

aws configure set default.region $aws_region
aws configure set aws_access_key_id $aws_access_key_id
aws configure set aws_secret_access_key $aws_secret_access_key
aws configure set aws_session_token $aws_session_token

aws configure set profile.$mfa_profile.region $aws_region
aws configure set profile.$mfa_profile.aws_access_key_id $aws_access_key_id
aws configure set profile.$mfa_profile.aws_secret_access_key $aws_secret_access_key
aws configure set profile.$mfa_profile.aws_session_token $aws_session_token

echo ""
echo "aws access key       $aws_access_key_id"
echo "aws secret key       $aws_secret_access_key"
echo "aws session token    $aws_session_token"
echo "aws expiration       $aws_expiration"
echo ""
echo "default and $mfa_profile profiles have been updated with MFA-protected temporary credentials"
echo ""
