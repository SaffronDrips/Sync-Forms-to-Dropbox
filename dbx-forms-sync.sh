#!/bin/bash

# Read credentials from "credentials.txt" file
credentials_file="credentials.txt"
if [[ ! -f "$credentials_file" ]]; then
  echo "Error: Credentials file not found."
  exit 1
fi

# Ensure there is a newline at the end of the file
echo >> "$credentials_file"

FORMS_API_KEY=""
FORMS_API_SECRET=""
DROPBOX_REFRESH_TOKEN=""
DROPBOX_APP_KEY=""
DROPBOX_APP_SECRET=""
DROPBOX_ACCESS_TOKEN=""
CSV_FOLDER="./CSV"
FORMS_FOLDER="./PDFs"
#ZIPS_FOLDER="./ZIPs"

#create the folders in case they don't exist
mkdir $CSV_FOLDER
mkdir $FORMS_FOLDER
#mkdir $ZIPS_FOLDER

# Read API Key, API Secret, and Dropbox Access Token from the credentials file
while IFS='=' read -r key value; do
  if [[ "$key" == "FORMS_API_KEY" ]]; then
    FORMS_API_KEY="${value}"
    echo "FORMS_API_KEY: $FORMS_API_KEY"
  elif [[ "$key" == "FORMS_API_SECRET" ]]; then
    FORMS_API_SECRET="${value}"
    echo "FORMS_API_SECRET: $FORMS_API_SECRET"
  elif [[ "$key" == "DROPBOX_REFRESH_TOKEN" ]]; then
    DROPBOX_REFRESH_TOKEN="${value}"
    echo "DROPBOX_REFRESH_TOKEN: $DROPBOX_REFRESH_TOKEN"
  elif [[ "$key" == "DROPBOX_APP_KEY" ]]; then
    DROPBOX_APP_KEY="${value}"
    echo "DROPBOX_APP_KEY: $DROPBOX_APP_KEY"
  elif [[ "$key" == "DROPBOX_APP_SECRET" ]]; then
    DROPBOX_APP_SECRET="${value}"
    echo "DROPBOX_APP_SECRET: $DROPBOX_APP_SECRET"
  fi
done < "$credentials_file"

if [[ -z "$FORMS_API_KEY" || -z "$FORMS_API_SECRET" || -z "$DROPBOX_REFRESH_TOKEN" || -z "$DROPBOX_APP_KEY" || -z "$DROPBOX_APP_SECRET" ]]; then
  echo "Error: Invalid credentials in the credentials file."
  exit 1
fi

#echo "$FORMS_API_KEY"

#Get token using API credentials
forms_token=$(curl -s -X GET https://api.helloworks.com/v3/token/$FORMS_API_KEY \
  -H "Authorization: Bearer $FORMS_API_SECRET") 

JWT=$(echo "$forms_token" | jq -r '.data.token')

echo "\n Your forms JWT is: $JWT \n"

# Make API request to retrieve all workflows
response=$(curl -s -X GET https://api.helloworks.com/v3/workflows \
  -H "Authorization: Bearer $JWT")

#temporary eceho for dev purposes - comment out later
#echo "List Workflows Response: \n $response \n"

# Extract GUIDs from the API response and store them in an array
# Store all the GUIDs in an array using a temporary file
temp_file=$(mktemp)
temp_file_names=$(mktemp)

echo "$response" | jq -r '.data[].guid' > "$temp_file"
echo "$response" | jq -r '.data[].name' > "$temp_file_names"

# Read the GUIDs & workflow names from the temporary files into an arrays
guids=()
workflow_names=()

#guids into array
while IFS= read -r guid; do
  guids+=("$guid")
done < "$temp_file"

#workflow names into array
while IFS= read -r name; do
  workflow_names+=("$name")
done < "$temp_file_names"


# Remove the temporary file
rm "$temp_file"
rm "$temp_file_names"

#echo GUIDS list for debugging purposes - comment out later
for i in ${!guids[@]}
  do
  echo "guids: ${guids[i]}, ${workflow_names[i]}"
  done


# Declare empty parellel arrays to store values from the first and second columns
#one for IDs and one for the name of the first signer for that instance
instance_ids=()
form_n_signer_names=()

# Loop through each GUID and download the workflow CSV
for i in "${!guids[@]}"; do
  file_name="${workflow_names[i]}.zip"
  
  echo "Downloading CSV for Workflow GUID: ${guids[i]}"
  curl -s -o "$file_name" -X POST https://api.helloworks.com/v3/workflows/${guids[i]}/csv \
  -H "Authorization: Bearer $JWT" \
  -H "Content-Type: application/x-www-form-urlencoded" 
  #  --data-urlencode "start_date=2023-01-01T09:35:00Z" \
  #  --data-urlencode "end_date=2023-06-01T09:35:00Z"
  
   echo "ZIP for CSV downloaded for Workflow GUID: ${workflow_names[i]} - ${guids[i]} "
  # Unzip the file
  unzip -o "$file_name" -d "$CSV_FOLDER"
 # Delete the ZIP file
  rm "$file_name"
  echo "Deleted CSV ZIP File: $file_name"
  echo "#############################################"

done

#Store every file name in CSV folder in an array
#TODO
csv_files=()
# Store the list of file names in CSV_FOLDER in a temporary file
temp_file=$(mktemp)
find "$CSV_FOLDER" -type f > "$temp_file"

# Store the file names from the temporary file into an array
csv_files=()
while IFS= read -r file; do
  csv_files+=("$file")
  #echo "CSV file name: $file"
done < "$temp_file"

# Remove the temporary file
rm "$temp_file"
  
# Read the first and second column values and store them in separate arrays
# Store the ids in the first column of each CSV file in an array
instance_ids=()
# Store the names in the second column of each CSV file in an array
form_n_signer_names=()

for file in "${csv_files[@]}"; do
 
  # Read the values in the first and second columns
  values1=()
  values2=()
  #flag variable to ignore first row of csv
  first_row=true
  #variable to capture form name if it's not an empty string.
  form_name="${file:6}"
  while IFS=, read -r value1 value2 _; do
  
  # skip the first row of the CSV 
  if $first_row; then
      first_row=false
      continue
    fi
    values1+=("$value1")
    values2+=("$form_name - $value2")
    #echo "Values: $value1 + $value2"
  done < "$file"

# Add the values to the respective arrays
  instance_ids+=("${values1[@]}")
  form_n_signer_names+=("${values2[@]}")
done

#This block is for debugging purposes - it prints the values in the parallel arrays captures from the CSV
# for i in "${!instance_ids[@]}"; do
#   echo "C1: ${instance_ids[i]} \nC2 ${form_n_signer_names[i]} \n"
#   done

# Loop through each value and download the workflow instance documents
  for i in "${!instance_ids[@]}"; do
    file_name="${form_n_signer_names[i]} - ${instance_ids[i]}"

  #check if folder exists - if yes, skip download for that form since it's already been downloaded
  if [ -d "$FORMS_FOLDER/$file_name" ]; then
    echo "The folder already exists for $file_name. Skipping download."
  else
    echo "Downloading documents for Workflow Instance ID: ${instance_ids[i]} that was sent to ${form_n_signer_names[i]}"
    #Download API Call 
    curl -s -o "$file_name.zip" -X GET https://api.helloworks.com/v3/workflow_instances/${instance_ids[i]}/documents \
    -H "Authorization: Bearer $JWT"
    
    #print download confirmation
    echo "Documents downloaded for Workflow Instance ID: ${instance_ids[i]} that was sent to ${form_n_signer_names[i]}"
  
    #Create Folder to unzip Forms from this workflow into
    mkdir "$FORMS_FOLDER/$file_name"
    echo "Unzipping $file_name"
    unzip -o -q "$file_name" -d "$FORMS_FOLDER/$file_name"
    # Delete the ZIP file
    #mv "$file_name.zip" "$ZIPS_FOLDER"
    echo "Deleted ZIP File: $file_name"
    rm "$file_name.zip"
    echo "############################################################"
  fi
done

echo "/n"
echo "###################################"
echo "Forms downloaded to local folder!"
echo "###################################"


#############################################################################################
#     #DROPBOX API UPLOAD - Take the downloaded forms and upload them to a Dropbox folder   #
#############################################################################################


## Compress the downloaded pdfs and csvs from Forms ###
    zip -r forms.zip CSV PDFs


#### Use refresh token to create a new access token ####
   DROPBOX_ACCESS_TOKEN=$( curl https://api.dropbox.com/oauth2/token \
      -d grant_type=refresh_token \
      -d refresh_token=$DROPBOX_REFRESH_TOKEN \
      -d client_id=$DROPBOX_APP_KEY \
      -d client_secret=$DROPBOX_APP_SECRET | jq -r .access_token )

## Save the current time to insert in uploaded zip name ##
    TIME=$( date )

#### Upload the zip containing all downloaded files to Dropbox folder: Apps/<app name>/Forms ####
    curl -X POST https://content.dropboxapi.com/2/files/upload \
      --header "Authorization: Bearer $DROPBOX_ACCESS_TOKEN" \
      --header "Dropbox-API-Arg: {\"path\":\"/Forms/Uploaded Forms at ${TIME}.zip\"}" \
      --header "Content-Type: application/octet-stream" \
      --data-binary "@forms.zip"

## Delete zip folder from local directory ##
      rm forms.zip

echo "/n"
echo "###########################"
echo "Upload to Dropbox Complete!"
echo "###########################"


