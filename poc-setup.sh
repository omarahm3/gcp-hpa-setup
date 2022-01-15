#!/usr/bin/env bash

help_text() {
  echo "=================== GKE Custom Metrics HPA PoC ==================="
  echo "This will setup a new GKE cluster, Pub/Sub topic, and Service Account. Will also deploy a python application to publish and consume the Pub/Sub topic."
  echo "Finally it will apply a custom metrics over the Pub/Sub topic that you can check under Cloud Monitoring, then it will HPA the deployment based on the number of queue undelivered messages"
  echo
  echo "* Check the metrics on Cloud Monitoring"
  echo "Resource type:  [ pubsub_subscription ]"
  echo "Metric:         [ pubsub.googleapis.com/subscription/num_undelivered_messages ]"
  echo

  echo "------------------------------------------------------------------"
  echo "- Project ID:           $PROJECT_ID"
  echo "- Project Name:         $PROJECT_NAME"
  echo "- Project Zone:         $PROJECT_ZONE"
  echo "- Topic Name:           $TOPIC_NAME"
  echo "- Subscription Name:    $SUBSCRIPTION_NAME"
  echo "- Cluster Admin:        $CLUSTER_ADMIN"
  echo "- Files Path:           $FILES"
  echo "- Logs Path:            $LOGS"
  echo "- Secrets Path:         $SECRETS"
  echo "- Current Path:         $CWD"
  echo "- Load Test #Messages:  $LOAD_TEST_MESSAGES_LIMIT"
  echo "- Load Test #Threads:   $LOAD_TEST_PARALLEL_THREADS"
  echo "------------------------------------------------------------------"
  echo
  echo
}

clean() {
  directory_exists $FILES && rm -rf $FILES
  directory_exists $SECRETS && rm -rf $SECRETS
  directory_exists $LOGS && rm -rf $LOGS
}

setup() {
  log "Checking required commands"
  command_exists git
  command_exists gcloud
  command_exists kubectl
  
  log "Creating required directories"
  # Create a working directory to hold our temporary files
  create_directory $FILES

  # Create logs directory
  create_directory $LOGS

  # Create secrets directory
  create_directory $SECRETS

  log "Setting needed gcloud configurations"
  # Set gcloud default configurations
  gcloud config set compute/zone $PROJECT_ZONE
  gcloud config set project $PROJECT_ID
  log "Done"
}

setup_gke_cluster() {
  log "Creating GKE cluster [$PROJECT_NAME]"
  gcloud container clusters create $PROJECT_NAME -q

  log "Adding current user [$CLUSTER_ADMIN] as cluster admin"
  kubectl create clusterrolebinding cluster-admin-binding --clusterrole cluster-admin --user $CLUSTER_ADMIN

  log "Setup k8s-stackdriver custom metrics"
  kubectl apply -f https://raw.githubusercontent.com/GoogleCloudPlatform/k8s-stackdriver/master/custom-metrics-stackdriver-adapter/deploy/production/adapter_new_resource_model.yaml
  log "Done"
}

setup_pub_sub_topic() {
  log "Enabling Pub/Sub API"
  gcloud services enable cloudresourcemanager.googleapis.com pubsub.googleapis.com -q

  log "Creating topic [$TOPIC_NAME]"
  gcloud pubsub topics create $TOPIC_NAME -q

  log "Creating subscription [$SUBSCRIPTION_NAME]"
  gcloud pubsub subscriptions create $SUBSCRIPTION_NAME --topic=$TOPIC_NAME -q
  log "Done"
}

setup_service_account() {
  log "Creating service account"
  gcloud iam service-accounts create $PROJECT_NAME-sa --display-name $PROJECT_NAME-USER -q

  log "Adding IAM policy"
  gcloud projects add-iam-policy-binding $PROJECT_ID --member "serviceAccount:$PROJECT_NAME-sa@$PROJECT_ID.iam.gserviceaccount.com" --role "roles/pubsub.subscriber" -q

  log "Downloading service account key to [$SECRETS/key.json]"
  gcloud iam service-accounts keys create $SECRETS/key.json --iam-account $PROJECT_NAME-sa@$PROJECT_ID.iam.gserviceaccount.com -q

  log "Importing service account key to cluster"
  kubectl create secret generic pubsub-key --from-file=key.json=$SECRETS/key.json
  log "Done"
}

setup_app() {
  log "Cloning samples repository"
  git clone --progress https://github.com/GoogleCloudPlatform/kubernetes-engine-samples.git $FILES/samples

  cd $FILES/samples/cloud-pubsub

  log "Applying pubsub-with-secret file"
  kubectl apply -f deployment/pubsub-with-secret.yaml

  log "Applying HPA"
  kubectl apply -f deployment/pubsub-hpa.yaml

  cd $CWD

  log "Done"
}

load_test() {
  log "Starting to load test by running [$LOAD_TEST_PARALLEL_THREADS] Threads each will send [$LOAD_TEST_MESSAGES_LIMIT] Message"
  i=1
  while [[ $i -le $LOAD_TEST_PARALLEL_THREADS ]]
  do
    j=1
    while [[ $j -le $LOAD_TEST_MESSAGES_LIMIT ]]
    do
      MESSAGE="Load Test Message [$i][$j]"
      log "Sending message ($MESSAGE)" &
      gcloud pubsub topics publish $TOPIC_NAME --message="$MESSAGE" &
      ((j=j+1))
    done
    ((i=i+1))
  done

  log "Done"
}

get_pubsub_deployment() {
  log "Getting deployments"
  kubectl get deploy/pubsub
}

clean_gcp() {
  log "Removing Pub/Sub subscription"
  gcloud pubsub subscriptions delete $SUBSCRIPTION_NAME -q

  log "Removing Pub/Sub topic"
  gcloud pubsub topics delete $TOPIC_NAME -q

  log "Removing GKE cluster"
  gcloud container clusters delete $PROJECT_NAME -q

  log "Removing service account"
  gcloud iam service-accounts delete $PROJECT_NAME-sa@$PROJECT_ID.iam.gserviceaccount.com  -q
}
