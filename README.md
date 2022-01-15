# GKE HPA Setup

![image](https://user-images.githubusercontent.com/8606113/149620318-8974a0ce-db63-47b9-89ea-c7c98d6ae161.png)

This is a small PoC that setup a new GKE cluster, pub/sub topic, and service account to apply a custom metrics over the Pub/Sub topic that you can check under Cloud Monitoring and manage autoscale the deployment based on the number of topic undelivered messages.

## Setup
on `./vars.sh` you can change whatever value you need, mostly its this:

```bash
CWD=$(pwd) # (no need to change) Current working directory that script will run on
FILES=./files # (no need to change) Files directory that script will use to write files to
SECRETS=$FILES/secrets # (no need to change) Script will use it to write GCP key file to
LOGS=./logs # Logs directory where we output each function log separately under a file with the same name as the function
PROJECT_ID=mrg-hpa-2133124 # your GCP project ID
PROJECT_NAME=mrg-hpa # Obviously project name
PROJECT_ZONE=europe-west1-d # GCP zone
TOPIC_NAME=echo # Your GCP Pub/Sub topic name
CLUSTER_ADMIN=$(gcloud config get-value account) # Script will be using this user to add it to created cluster as admin
SUBSCRIPTION_NAME=$TOPIC_NAME-read # Subscription name
LOAD_TEST_MESSAGES_LIMIT=100 # For load testing, this will be the number of message to publish to the topic
LOAD_TEST_PARALLEL_THREADS=1 # For load testing, this is the number of times that LOAD_TEST_MESSAGES_LIMIT will be sent
```

## Run
Simply run it by typing:

```bash
cd gke-hpa-setup
./run-poc.sh
```

You'll be prompted with a text explaining what this script is, beside the variables that will be used, make sure to review them and then click any key to run the script, or the classic ctrl + c to exit.

## Cleanup
Script will auto cleanup anyway, removing all the resources it created, but in case script with abruptly closed, you can always run:

```bash
./clean.sh
```

## Load testing
In case you want to adjust load testing function and try, you can always run the load testing part separately by just:

```bash
./load-test.sh
```
