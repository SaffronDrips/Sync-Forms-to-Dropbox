# Sync-Forms-to-Dropbox

### - This bash script downloads all your copmleted Dropbox Forms & CSV Reports for the past 6 Months and uploads them to dropbox
### - You can configure the start and end date of the 6 month window to get documents completed more than 6 months ago (Found on Line 117-118)
### - You can schedule it so it sync your completed documents on a set schedule (daily, hourly, or weekly etc) using a cron job. 
### - You need to set up an automatino rule in dropbox to automatically unzip the uploaded package in the target folder. Instructions are included for that.


_________________________________________________________________________________________________

## Set-Up Instructions:

#### Before Beginning:
1. - The 'jq' bash command must be installed. If it is not installed, here's a guide for installing it. https://jqlang.github.io/jq/download/#:~:text=jq%20is%20in%20the%20official,using%20sudo%20dnf%20install%20jq%20.
2. - You will need your Dropbox Forms API KEY and API Secret. Here's a guide to getting those from your Dropbox Forms Web app. Here is a guide for getting your API credentials. Here is a video guide that covers the set-up process as well: https://capture.dropbox.com/VKTEgysfDYgsU4Tn
<br> https://helloworks.zendesk.com/hc/en-us/articles/360026065611-How-to-find-your-Public-Private-API-key
3. - You will need to set-up an API app in your Dropbox Console. This video shows you how to do that: https://capture.dropbox.com/zfpdbxAeOktgvieA

#### Steps:
1. Download the files in this repository. You may need to unzip them.
2. Open the credentials.txt file
3. Copy and Paste your API_KEY and API_SECRET from your Dropbox Forms Web Console beside the "=" of each credential. It should look like the example below:  <br>
      FORMS_API_KEY=123fsadas12421312  <br>
      FORMS_API_SECRET=3412312eqweqw342  <br>
4. If you would like your files to be downloaded to specific folder or a sync folder, move these files into the folder you wish to have all your completed forms downloaded in
5. Run the script. One way to do this is to open a terminal instance in your current folder and executing this command "sh bulk-download.sh"
6. Your completed forms and CSV reports will begin downloading now
7. You can see a log of all the downloaded files in the terminal

### Setting Up an Automated Dropbox Folder for Unzipping The Uploaded File
Dropbox Folder Automations

1. Sign in to dropbox.com.
2. Click the folder where your Forms will be uploaded to.
3. Click on the settings menu and click  "Add Automation". If you don't see the "add automation option", hover over the "Organize option" and it should appear in that sub-menu. 
4. Select the autoamtion "Unzip Files"
5. When you’ve added all your options, click Save.

*Only available to users on Dropbox Professional, Standard, Advanced, and Enterprise plans



