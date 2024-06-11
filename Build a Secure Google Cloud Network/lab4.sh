gcloud compute instances create vm-appliance \ 
--zone $ZONE --machine-type e2-standard-4 \ 
--network-interface network=privatenet,subnet=privatesubnet-us \
--network-interface network=managementnet,subnet=managementsubnet-us \
--network-interface network=mynetwork,subnet=mynetwork \

#Enable IAP (Identitiy Aware Proxy) in GCP UI Console.

gcloud compute firewall-rules list
gcloud compute networks list
gcloud compute firewall-rules describe open-access
gcloud compute firewall-rules delete open-access
gcloud compute instances list
gcloud compute instances start bastion
ZONE=us-east1-b SSH_IAP=permit-ssh-iap-ingress-ql-713 ALLOW_INT=permit-http-ingress-ql-713 SSH_RULE=permit-ssh-internal-ingress-ql-713

#Create firewall rules that contains all IP addresses that IAP uses for TCP forwarding
gcloud compute firewall-rules create allow-ssh-from-bastion \
--source-ranges 35.235.240.0/20 --direction INGRESS --allow tcp:22 --target-tags $SSH_IAP --network acme-vpc

gcloud compute instances remove-tags bastion --tags all --zone $ZONE
gcloud compute instances add-tags bastion --tags $SSH_IAP --zone $ZONE

gcloud compute firewall-rules create allow-http-to-fe --network acme-vpc --direction INGRESS --allow tcp:80 --target-tags $ALLOW_INT
gcloud compute instances remove-tags juice-shop --tags all --zone $ZONE
gcloud compute instances add-tags juice-shop --tags $ALLOW_INT --zone $ZONE

gcloud compute networks subnets list --filter 'name=("acme-mgmt-subnet")'
gcloud compute firewall-rules create allow-ssh-from-bastion-subnet \
--network acme-vpc --source-ranges 192.168.10.2/32,192.168.10.0/24 \
--direction INGRESS --allow tcp:22 
--target-tags $SSH_RULE

gcloud compute instances add-tags juice-shop --tags $SSH_RULE --zone $ZONE

