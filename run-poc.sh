#!/usr/bin/env bash

source ./vars.sh
source ./common.sh
source ./poc-setup.sh

help_text

read -p "Press any key to start the run, or ctrl+c to exit" key

echo "###########################################"
echo "[*]>> Cleaning files & folders"
clean
echo
echo

echo "###########################################"
echo "[*]>> Setup needed configurations"
setup
echo
echo

echo "###########################################"
echo "[*]>> Setup GKE cluster"
call_and_log setup_gke_cluster
echo
echo

echo "###########################################"
echo "[*]>> Setup Pub/Sub topic"
call_and_log setup_pub_sub_topic
echo
echo

echo "###########################################"
echo "[*]>> Setup service account"
call_and_log setup_service_account
echo
echo

echo "###########################################"
echo "[*]>> Clone and apply application"
call_and_log setup_app
echo
echo

sleep 20

echo "###########################################"
echo "[*]>> Current deployment [Before Load Test]"
call_and_log get_pubsub_deployment
echo
echo

echo "###########################################"
echo "[*]>> Starting load testing"
call_silent load_test
echo
echo

wait

echo "###########################################"
echo "[*]>> Current deployment [After Load Test]"
call_and_log get_pubsub_deployment
echo
echo

echo "###########################################"
echo "[*]>> Load test finished, press any key to cleanup"
echo
echo

read -p "Press any key to clean up, or ctrl+c to exit" key

echo "###########################################"
echo "[*]>> Cleaning GCP services"
call_and_log clean_gcp
