gcloud app create --project $DEVSHELL_PROJECT_ID --region europe-west4
gcloud app deploy
gcloud app describe

#Enable IAP and Configure OAuth 
#User _gcp_iap/clear_login_cookie to clear cookies

#To create a SSL self-signed certificate
# 1 : Create a private key file in RSA 2048
openssl genrsa -out PRIVATE_KEY_FILE 2048

# 2 : Create a Cert Signing Request(CSR) in .pem Forat
openssl req -new -key PRIVATE_KEY_FILE -out CSR_FILE -config ssl_config

# 3 : Signing the CSR with own CA
openssl x509 -req -signkey PRIVATE_KEY_FILE -in CSR_FILE -out CERTIFICATE_FILE.pem \
-extfile ssl_config  -extensions extension_requirement  -days 365

# 4 : Creation of SSL Cert that ready to attach to lb/server
gcloud compute ssl-certificates create SSL_CERT --certificate CERTIFICATE_FILE.pem --private-key PRIVATE_KEY_FILE --global

