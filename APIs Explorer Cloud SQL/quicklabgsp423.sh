# Enable colors for informative messages (optional)
BLACK=`tput setaf 0`
RED=`tput setaf 1`
GREEN=`tput setaf 2`
YELLOW=`tput setaf 3`
RESET=`tput sgr0`

# Variables for reusability
INSTANCE_NAME="my-instance"
DATABASE_NAME="mysql-db"
DATASET_NAME="mysql_db"
TABLE_NAME="info"
BUCKET_NAME="my-bucket-$PROJECT_ID"  # Add a unique identifier to avoid name conflicts

echo "${YELLOW}Starting Execution...${RESET}"

# Retrieve project ID from gcloud
export PROJECT_ID=$(gcloud info --format='value(config.project)')
if [ -z "$PROJECT_ID" ]; then
  echo "${RED}Failed to retrieve project ID.${RESET}"
  exit 1
fi

# Create Cloud SQL instance
gcloud services enable sqladmin.googleapis.com
if [ $? -ne 0 ]; then
  echo "${RED}Failed to enable Cloud SQL Admin API.${RESET}"
  exit 1
fi

# Sleep for a bit to ensure service is enabled
sleep 15

gcloud sql instances create $INSTANCE_NAME \
  --project=$PROJECT_ID \
  --database-version=MYSQL_5_7 \
  --tier=db-n1-standard-1

if [ $? -ne 0 ]; then
  echo "${RED}Failed to create Cloud SQL instance.${RESET}"
  exit 1
fi

echo "${GREEN}Task 1: Cloud SQL instance created.${RESET}"

# Create Cloud SQL database
gcloud sql databases create $DATABASE_NAME \
  --instance=$INSTANCE_NAME \
  --project=$PROJECT_ID

if [ $? -ne 0 ]; then
  echo "${RED}Failed to create Cloud SQL database.${RESET}"
  exit 1
fi

echo "${GREEN}Task 2: Cloud SQL database created.${RESET}"

# Create BigQuery dataset
bq mk --dataset $PROJECT_ID:$DATASET_NAME
if [ $? -ne 0 ]; then
  echo "${RED}Failed to create BigQuery dataset.${RESET}"
  exit 1
fi

# Create BigQuery table (use standard SQL syntax)
bq query --use_legacy_sql=false \
"CREATE TABLE \`$PROJECT_ID.$DATASET_NAME.$TABLE_NAME\` (
  name STRING,
  age INT64,
  occupation STRING
);"

if [ $? -ne 0 ]; then
  echo "${RED}Failed to create BigQuery table.${RESET}"
  exit 1
fi

echo "${GREEN}Task 3: BigQuery table created.${RESET}"

# Prepare employee data
cat > employee_info.csv <<EOF
"Sean", 23, "Content Creator"
"Emily", 34, "Cloud Engineer"
"Rocky", 40, "Event coordinator"
"Kate", 28, "Data Analyst"
"Juan", 51, "Program Manager"
"Jennifer", 32, "Web Developer"
EOF

# Create Cloud Storage bucket
gsutil mb gs://$BUCKET_NAME
if [ $? -ne 0 ]; then
  echo "${RED}Failed to create Cloud Storage bucket.${RESET}"
  exit 1
fi

# Upload data to Cloud Storage
gsutil cp employee_info.csv gs://$BUCKET_NAME/
if [ $? -ne 0 ]; then
  echo "${RED}Failed to upload data to Cloud Storage.${RESET}"
  exit 1
fi

# Grant storage admin role to Cloud SQL service account
SERVICE_EMAIL=$(gcloud sql instances describe $INSTANCE_NAME \
  --format="value(serviceAccountEmailAddress)")

gsutil iam ch serviceAccount:$SERVICE_EMAIL:roles/storage.admin gs://$BUCKET_NAME/
if [ $? -ne 0 ]; then
  echo "${RED}Failed to grant storage admin role.${RESET}"
  exit 1
fi

echo "${GREEN}Task 4: Data uploaded and permissions granted.${RESET}"

echo "${GREEN}Lab completed successfully!${RESET}"

exit 0
