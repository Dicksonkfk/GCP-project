REGION=us-east1 ZONE=us-east1-d
NUCLEUS_HOST_NAME=nucleus-jumphost-647
FIREWALL_RULE_MIG=allow-tcp-rule-377

gcloud compute networks create nucleus-vpc 
gcloud compute networks subnets create nucleus-mgmt-subnet --network nucleus-vpc --region $REGION --range 10.2.0.0/24
gcloud compute instances create $NUCLEUS_HOST_NAME \
--zone=$ZONE \
--machine-type e2-micro \
--image-family debian-11 \
--image-project debian-cloud \
--network nucleus-vpc\
--subnet nucleus-mgmt-subnet

gcloud compute firewall-rules create nucleus-vpc-ssh-rule --network nucleus-vpc --subnet nucleus-mgmt-subnet --allow tcp:22,icmp --direction EGRESS --source-ranges 10.2.0.2/32

gcloud beta container clusters create private-cluster \
--zone=$ZONE \
--num-nodes 1 \
--enable-master-authorized-networks \
--master-authorized-networks 10.2.0.2/32

gcloud container clusters get-credentials private-cluster \
--zone=$ZONE

gcloud compute ssh $NUCLEUS_HOST_NAME --zone=$ZONE
sudo apt-get install kubectl && sudo apt-get install google-cloud-sdk-gke-gcloud-auth-plugin
kubectl get nodes --output wide 

kubectl create deployment hello-server --image=gcr.io/google-samples/hello-app:1.0
kubectl expose deployment hello-server \
--name orca-hello-service \
--type LoadBalancer \
--port 8081

gcloud compute target-pools create frontend-pools
gcloud compute forwarding-rules create $FIREWALL_RULE_MIG --target-pool frontend-pools --region $REGION --ports 80 

gcloud compute networks subnets create nucleus-infra-subnet --network nucleus-vpc --region $REGION --range 10.0.0.20/24
cat <<EOF > startup.sh
#! /bin/bash
apt-get update
apt-get install -y nginx
service nginx start
sed -i -- 's/nginx/Google Cloud Platform - '"\$HOSTNAME"'/' /var/www/html/index.nginx-debian.html
EOF

gcloud compute instance-templates create lb-backend-template \
--region=$Region \
--network nucleus-vpc \
#--subnet nucleus-infra-subnet \
--tags allow-health-check \
--machine-type e2-medium \
--image-family debian-11 \
--image-project debian-cloud \
--metadata=startup-script=startup.sh


gcloud compute instance-groups managed create backend-instance-group --target-pool frontend-pools --template lb-backend-template --size 2 --zone=$ZONE
gcloud compute firewall-rules create $FIREWALL_RULE_MIG --allow tcp:80 --direction INGRESS --network nucleus-vpc --target-tags allow-health-check
gcloud compute health-checks create http http-health-check --global

gcloud compute backend-services create http-website-service \
--health-checks http-health-check \
--port-name http \
--protocol HTTP \
--global

gcloud compute backend-services add-backend http-website-service \
--instance-group backend-instance-group  \
--instance-group-zone=$ZONE \
--global

gcloud compute url-maps create urlmaps --default-service http-website-service
gcloud compute target-http-proxies create http-website-proxy --url-map urlmaps
gcloud compute forwarding-rules create frontend-2-backend-rules \
--ports 80 \
--global \
--target-http-proxy http-website-proxy