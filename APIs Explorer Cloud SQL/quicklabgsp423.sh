# Enable colors for informative messages (optional)
BLACK=`tput setaf 0`
RED=`tput setaf 1`
GREEN=`tput setaf 2`
YELLOW=`tput setaf 3`
RESET=`tput sgr0`

echo "${YELLOW}Starting Execution..."${RESET}

# Retrieve project ID from gcloud
export PROJECT_ID=$(gcloud info --format='value(config.project)')

# Create Cloud SQL instance
gcloud services enable sqladmin.googleapis.com
sleep 10

gcloud sql instances create my-instance \
  --project=$PROJECT_ID \
  --database-version=MYSQL_5_7 \
  --tier=db-n1-standard-1

echo "${GREEN}Task 1: Cloud SQL instance created.${RESET}"

# Create Cloud SQL database
gcloud sql databases create mysql-db \
  --instance=my-instance \
  --project=$PROJECT_ID

echo "${GREEN}Task 2: Cloud SQL database created.${RESET}"

# Create BigQuery dataset
bq mk --dataset $PROJECT_ID:mysql_db

# Create BigQuery table (use standard SQL syntax)
bq query --use_legacy_sql=false \
"CREATE TABLE \`$PROJECT_ID.mysql_db.info\` (
  name STRING,
  age INT64,
  occupation STRING
);"

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
gsutil mb gs://$PROJECT_ID

# Upload data to Cloud Storage
gsutil cp employee_info.csv gs://$PROJECT_ID/

# Grant storage admin role to Cloud SQL service account
SERVICE_EMAIL=$(gcloud sql instances describe my-instance \
  --format="value(serviceAccountEmailAddress)")

gsutil iam ch serviceAccount:$SERVICE_EMAIL:roles/storage.admin gs://$PROJECT_ID/

echo "${GREEN}Task 4: Data uploaded and permissions granted.${RESET}"

echo "${GREEN}Lab completed successfully!${RESET}"

# Removed subscription prompt (optional)
# ...

exit 0
