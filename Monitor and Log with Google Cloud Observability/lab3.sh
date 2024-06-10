#Scripts for installing the Monitoring and Logging agents
gcloud compute ssh $VM_NAME --zone $ZONE
curl -sSO https://dl.google.com/cloudagents/add-google-cloud-ops-agent-repo.sh
sudo bash add-google-cloud-ops-agent-repo.sh --also-install
sudo systemctl status google-cloud-ops-agent"*"


gcloud functions deploy helloWorld \
--gen2 \
--runtime nodejs20 \
--region $REGION \
--source . \
--max-instances 5 \
--entry-point=helloGET \
--trigger-http \
--allow-unauthenticated 

gcloud compute instances add-metadata video-queue-monitor --metadata  

gcloud compute instances add-metadata video-queue-monitor --metadata  startup-script='#!/bin/bash
ZONE="$ZONE"
REGION="${ZONE%-*}"
PROJECT_ID="$DEVSHELL_PROJECT_ID"'


cd ../..
cd go 
sudo chmod 777 /usr/local
sudo tar vzxf go1.19.6.linux-amd64.tar.gz

export PATH=$PATH:/usr/local/go/bin
sudo apt get update && apt install -y
export GOPATH=/work/go
export GOCACHE=/work/go/cache
cd /work/go/video
gsutil cp gs://spls/gsp338/video_queue/main.go /work/go/video/main.go

go mod tidy
go run /work/go/video/main.go --zone us-west1-c

gcloud logging metrics create $METRICS_NAME  \
--description "oversized upload of videos"
--log-filter 'textPayload: "file_format: ([4,8]K).*"'
