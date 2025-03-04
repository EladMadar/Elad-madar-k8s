#!/bin/bash
# This script assumes the role EKSClusterAccessRole and updates your kubeconfig.
# Make sure you have AWS CLI and jq installed.
# Usage: ./update_kubeconfig.sh [session-name]

set -euo pipefail

# Use the provided session name or default to a timestamp-based one.
SESSION_NAME="${1:-eks-session-$(date +%s)}"
ROLE_ARN="arn:aws:iam::992382545251:role/EKSClusterAccessRole"
CLUSTER_NAME="eks-final-workshop"
REGION="us-east-1"

echo "Assuming role $ROLE_ARN with session name $SESSION_NAME..."

# Assume the role and capture the JSON output.
ASSUME_ROLE_OUTPUT=$(aws sts assume-role --role-arn "$ROLE_ARN" --role-session-name "$SESSION_NAME")

# Extract temporary credentials using jq.
export AWS_ACCESS_KEY_ID=$(echo "$ASSUME_ROLE_OUTPUT" | jq -r '.Credentials.AccessKeyId')
export AWS_SECRET_ACCESS_KEY=$(echo "$ASSUME_ROLE_OUTPUT" | jq -r '.Credentials.SecretAccessKey')
export AWS_SESSION_TOKEN=$(echo "$ASSUME_ROLE_OUTPUT" | jq -r '.Credentials.SessionToken')

echo "Temporary credentials acquired."

# Update kubeconfig using the assumed role credentials.
aws eks --region "$REGION" update-kubeconfig --name "$CLUSTER_NAME" --role-arn "$ROLE_ARN" --profile default

echo "kubeconfig updated successfully for cluster $CLUSTER_NAME using role $ROLE_ARN."
~