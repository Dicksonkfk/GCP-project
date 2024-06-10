gcloud compute instances create vm-appliance \ 
--zone $ZONE --machine-type e2-standard-4 \ 
--network-interface network=privatenet,subnet=privatesubnet-us \
--network-interface network=managementnet,subnet=managementsubnet-us \
--network-interface network=mynetwork,subnet=mynetwork \
