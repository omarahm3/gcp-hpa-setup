#!/usr/bin/env bash

CWD=$(pwd)
FILES=./files
SECRETS=$FILES/secrets
LOGS=./logs
PROJECT_ID=mrg-hpa-2133124
PROJECT_NAME=mrg-hpa
PROJECT_ZONE=europe-west1-d
TOPIC_NAME=echo
CLUSTER_ADMIN=$(gcloud config get-value account)
SUBSCRIPTION_NAME=$TOPIC_NAME-read
LOAD_TEST_MESSAGES_LIMIT=100
LOAD_TEST_PARALLEL_THREADS=1
