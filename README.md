# timestamper-iaas
A cloud-powered automation tool that generates YouTube chapter timestamps by analyzing MP4 videos. Uses Azure OpenAI, App Service, and managed PaaS services to automatically extract audio, process speech, and output formatted chapter markers.

## Architecture
1. Local Processing (NAS)
   - Watch folder for new MP4 files
   - Extract MP3 audio using ffmpeg
   - Upload to Azure Blob Storage

2. Cloud Processing 
   - Web API hosted in Azure App Service processes audio files
   - Azure Speech Services handles transcription
   - Azure OpenAI generates intelligent chapter markers
   - Results stored in blob storage

## Prerequisites
- Synology NAS or Linux system
- ffmpeg
- inotify-tools
- Azure CLI
- Azure subscription
- Storage account and container

## Setup

1. Install Azure CLI:
```bash
# For Synology, use Python pip
pip install azure-cli
```

2. Login to Azure:
```bash
az login
```

3. Create Azure resources:
```bash
# Create storage account
az storage account create \
    --name your-storage-account-name \
    --resource-group your-resource-group \
    --location eastus \
    --sku Standard_LRS

# Create container
az storage container create \
    --name audio-files \
    --account-name your-storage-account-name
```

4. Set permissions:
```bash
# Get your user's Object ID
USER_ID=$(az ad signed-in-user show --query id -o tsv)

# Assign Storage Blob Data Contributor role
az role assignment create \
    --role "Storage Blob Data Contributor" \
    --assignee-object-id $USER_ID \
    --scope "/subscriptions/your-subscription-id/resourceGroups/your-resource-group/providers/Microsoft.Storage/storageAccounts/your-storage-account-name"
```

5. Configure scripts:
- Update storage account name and container in `extract_audio.sh`
- Verify directories in `watcher_mp4.sh`

## Directory Structure
```
/volume1/shared-mount/
├── mp4s/              # Put MP4 files here
└── extracted_audio/   # Temporary MP3 storage
```

## Usage
1. Start the watcher:
```bash
./scripts/audio/watcher_mp4.sh
```

2. Drop MP4 files in the watch folder
3. Audio will be:
   - Extracted as MP3
   - Uploaded to Azure Blob Storage
   - Processed by App Service
   - Results stored back in blob storage

## Scripts

### watcher_mp4.sh
Monitors directory for new MP4 files and triggers processing.

### extract_audio.sh
Extracts audio and uploads to Azure Blob Storage.

## Contributing
[Add contributing guidelines]

## License
[Add license]
