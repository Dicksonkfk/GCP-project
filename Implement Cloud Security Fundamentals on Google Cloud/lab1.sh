#Declaration of global variable to be exported 
REGION=us-east1  ZONE=us-east1-d
#gcloud compute networks create orca-mgmt-network  
#gcloud compute networks subnets create orca-mgmt-subnet --network orca-mgmt-network --region $REGION --range 10.2.0.0/24

#Edit the roles according to the permission given in lab
vim roles.yaml
gcloud services enable cloudresourcemanager.googleapis.com
gcloud iam roles create orca_storage_editor_452 --project $DEVSHELL_PROJECT_ID --file roles.yaml


gcloud iam service-accounts create orca-private-cluster-256-sa --display-name "Service account for private cluster"
gcloud projects add-iam-policy-binding $DEVSHELL_PROJECT_ID --member serviceAccount:orca-private-cluster-256-sa@$DEVSHELL_PROJECT_ID.iam.gserviceaccount.com  --role roles/monitoring.viewer
gcloud projects add-iam-policy-binding $DEVSHELL_PROJECT_ID --member serviceAccount:orca-private-cluster-256-sa@$DEVSHELL_PROJECT_ID.iam.gserviceaccount.com  --role roles/monitoring.metricWriter
gcloud projects add-iam-policy-binding $DEVSHELL_PROJECT_ID --member serviceAccount:orca-private-cluster-256-sa@$DEVSHELL_PROJECT_ID.iam.gserviceaccount.com  --role roles/logging.logWriter 
gcloud projects add-iam-policy-binding $DEVSHELL_PROJECT_ID --member serviceAccount:orca-private-cluster-256-sa@$DEVSHELL_PROJECT_ID.iam.gserviceaccount.com  --role projects/$DEVSHELL_PROJECT_ID/roles/orca_storage_editor_452

gcloud compute networks subnets create orca-build-subnet \
--network orca-build-vpc \
--region $REGION \
--range 10.0.4.0/22 \
--enable-private-ip-google-access \
--secondary-range my-svc-range 10.0.32.0/20,my-pod-range 10.0.4.0/14


gcloud beta container clusters create orca-cluster-890  \
--enable-private-nodes  \
--enable-private-endpoint \
--enable-ip-alias \
--subnetwork orca-build-subnet \
--master-ipv4-cidr 172.16.0.0/28  \
--secondary-range my-svc-range 10.0.32.0/20,my-pod-range 10.0.4.0/14
--services-secondary-range-name my-svc-range \
--cluster-secondary-range my-pod-range \
--service-account orca-private-cluster-256-sa@$DEVSHELL_PROJECT_ID.iam.gserviceaccount.com \
--zone $ZONE 


gcloud compute instances create orca-jumphost --network orca-build-vpc --subnet orca-mgmt-subnet --zone $ZONE --scopes 'https://www.googleapis.com/auth/cloud-platform'
gcloud compute instances describe orca-jumphost --zone=$ZONE | grep natIP

gcloud container clusters update orca-cluster-890 \
--enable-master-authorized-networks \
--zone=$ZONE \
--master-authorized-networks 192.168.10.2/32

gcloud compute ssh orca-jumphost --zone $ZONE  
echo "sudo apt-get install kubectl && sudo apt-get install google-cloud-sdk-gke-gcloud-auth-plugin"
echo "export USE_GKE_GCLOUD_AUTH_PLUGIN=True" >> ~/.bashrc
source ~/.bashrc
gcloud container clusters get-credentials orca-cluster-890 --internal-ip --project qwiklabs-gcp-01-47f11c6d513b --zone europe-west1-d
kubcetl get nodes --output wide
kubectl create deployment hello-server --image=gcr.io/google-samples/hello-app:1.0
kubectl expose deployment hello-server \
--name orca-hello-service \
--type LoadBalancer \
--port 80 \
--target-port 8080




