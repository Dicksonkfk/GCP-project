gcloud app create --project $DEVSHELL_PROJECT_ID --region europe-west4
gcloud app deploy
gcloud app describe

#Enable IAP and Configure OAuth 
#User _gcp_iap/clear_login_cookie to clear cookies

