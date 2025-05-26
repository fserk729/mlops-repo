# Data Versioning and Model Containerization with DVC and Docker

This guide demonstrates how to implement data versioning using DVC (Data Version Control) and containerize ML models for deployment. You'll learn to track data changes, manage ML pipelines, and package models in Docker containers for scalable, reproducible MLOps workflows.

![mlops-data-versioning-containerization-design](assets/mlops-course-03-design.png)

## Prerequisites

* [Python](https://www.python.org)
* [Docker](https://docs.docker.com/get-docker/)
* [DVC](https://dvc.org/doc/install)
* [AWS CLI](https://aws.amazon.com/cli/)

## Problem Statement

As ML projects mature, several challenges emerge:
- **Data Drift**: Training data changes over time, requiring versioning
- **Pipeline Reproducibility**: Need to track data transformations and model training steps
- **Model Deployment**: Models need to be packaged consistently for production
- **Collaboration**: Teams need shared access to datasets and model artifacts

## Solution Architecture

This course implements:
- **DVC for Data Versioning and Pipeline Management**: Track large datasets and automate ML pipelines
- **Docker Containerization**: Package models for consistent deployment

## 1. Project Structure

```
mlops-course-03/
├── src/
│   ├── data/
│   ├── models/
│   ├── pipelines/
│   │   ├── clean.py          # Data cleaning pipeline
│   │   ├── ingest.py         # Data ingestion pipeline
│   │   ├── predict.py        # Model prediction pipeline
│   │   └── train.py          # Model training pipeline
│   ├── .gitignore            # Files to ignore in Git
│   ├── config.yml           # ML pipeline configuration
│   ├── main.py             # Main pipeline orchestrator
│   └── requirements.txt    # Python dependencies
├── terraform/              # Infrastructure as Code
└── README.md
```

## 2. Python Virtual Environment Setup (you can use [uv](https://docs.astral.sh/uv/) as an alternative)
```bash
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
```

## 2. DVC Remote Storage as a datastore
The role of a datastore is to store and manage collections of data. DVC works on top of Git and is language- and framework-agnostic. It can store data locally or in storage providers such as AWS S3, Azure Blob Storage, SFTP and HDFS; in our case, we will store it in AWS S3. To avoid performing diffs on large and potentially binary files, DVC creates MD5 hash of each file instead and those are versioned by Git.

### Initialize DVC Repository
```bash
cd mlops-course-03/src
dvc init
```

### Configure Remote Storage
DVC is configured to use your S3 bucket from mlops-course-02:

```yaml
# .dvc/config
[core]
    remote = storage
['remote "storage"']
    url = s3://mlops-course-ehb-data-dev/data
```

### Track Data with DVC
```bash
# Add data to DVC tracking
dvc add data/

# Push data to remote storage
dvc push

# Commit DVC files to Git
git add data.dvc .dvcignore
git commit -m "Add data tracking with DVC"
```

## 3. ML Pipeline Configuration

The `config.yml` file centralizes all pipeline parameters:

```yaml
data: 
  train_path: data/train.csv
  test_path: data/test.csv

train:
  test_size: 0.2
  random_state: 42
  shuffle: true

model:
  name: GradientBoostingClassifier
  params:
    max_depth: null
    n_estimators: 10
  store_path: models/
```

## 4. Pipeline Components

### Data Ingestion Pipeline
The `Ingestion` class loads training and test datasets:

```python
class Ingestion:
    def __init__(self):
        self.config = self.load_config()

    def load_data(self):
        train_data_path = self.config['data']['train_path']
        test_data_path = self.config['data']['test_path']
        train_data = pd.read_csv(train_data_path)
        test_data = pd.read_csv(test_data_path)
        return train_data, test_data
```

### Data Cleaning Pipeline
The `Cleaner` class handles data preprocessing:
- Removes unnecessary columns
- Handles missing values using imputation strategies
- Removes outliers using IQR method
- Preprocesses monetary values

### Model Training Pipeline
The `Trainer` class implements:
- **Preprocessing Pipeline**: StandardScaler, MinMaxScaler, OneHotEncoder
- **SMOTE**: Handles class imbalance
- **Model Selection**: Supports multiple algorithms (RandomForest, GradientBoosting, DecisionTree)
- **Model Persistence**: Saves trained models using joblib

### Model Prediction Pipeline
The `Predictor` class provides:
- Model loading from saved artifacts
- Batch prediction capabilities
- Model evaluation metrics (accuracy, ROC-AUC, classification report)

## 5. Running the ML Pipeline

### Install Dependencies
```bash
pip install -r requirements.txt
```

### Execute Complete Pipeline
```bash
python main.py
```

The pipeline will:
1. **Ingest** data from configured sources
2. **Clean** and preprocess the data
3. **Train** the specified model with SMOTE balancing
4. **Evaluate** model performance on test data
5. **Save** the trained model for deployment

### Sample Output
```
INFO:root:Data ingestion completed successfully
INFO:root:Data cleaning completed successfully  
INFO:root:Model training completed successfully
INFO:root:Model evaluation completed successfully

============= Model Evaluation Results ==============
Model: GradientBoostingClassifier
Accuracy Score: 0.8547, ROC AUC Score: 0.8932

              precision    recall  f1-score   support
           0       0.86      0.95      0.90      1500
           1       0.85      0.65      0.74       500

    accuracy                           0.85      2000
   macro avg       0.85      0.80      0.82      2000
weighted avg       0.85      0.85      0.85      2000
=====================================================
```

## 6. Data Version Management

### Updating Data
When new data arrives:
```bash
# Update your data files
# Then track the changes
dvc add data/
dvc push

# Commit the updated .dvc file
git add data.dvc
git commit -m "Update dataset v2.0"
git tag -a "data-v2.0" -m "Dataset version 2.0"
```

### Switching Data Versions
```bash
# Checkout specific data version
git checkout data-v1.0
dvc checkout

# Return to latest
git checkout main
dvc checkout
```

## 7. Model Containerization

### Create Dockerfile
```dockerfile
FROM python:3.9-slim

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

EXPOSE 8000

CMD ["python", "app.py"]
```

### Build and Run Container
```bash
# Build Docker image
docker build -t mlops-course-03:latest .

# Run container
docker run -p 8000:8000 mlops-course-03:latest
```

## 8. Infrastructure Integration

The course reuses infrastructure from mlops-course-02:
- **S3 Backend**: Terraform state management
- **S3 Data Storage**: DVC remote storage
- **Environment Configuration**: Dev/Test/Prod separation

### Deploy Infrastructure
```bash
cd terraform/
terraform init --backend-config='backends/dev.conf'
terraform plan --var-file='environments/dev.tfvars'
terraform apply --var-file='environments/dev.tfvars'
```

## 9. Best Practices Implemented

### Data Management
- **Version Control**: All data changes tracked with DVC
- **Remote Storage**: Centralized data access via S3
- **Data Validation**: Automated data quality checks

### Model Management  
- **Reproducible Pipelines**: Consistent model training process
- **Parameter Tracking**: All hyperparameters versioned in config
- **Model Artifacts**: Serialized models with metadata

### DevOps Integration
- **Containerization**: Models packaged for deployment
- **Infrastructure as Code**: Terraform for resource management
- **Pipeline Automation**: Automated ML workflows

## 10. Next Steps

This course establishes the foundation for advanced MLOps practices:
- **Model Monitoring**: Track model performance in production
- **A/B Testing**: Compare model versions
- **Auto-Retraining**: Trigger retraining on data drift
- **Multi-Environment Deployment**: Staging and production pipelines

## Key Benefits

✅ **Data Reproducibility**: Every dataset version is tracked and recoverable  
✅ **Pipeline Automation**: End-to-end ML workflow automation  
✅ **Scalable Deployment**: Containerized models for any environment  
✅ **Team Collaboration**: Shared data and model artifacts  
✅ **Production Ready**: Infrastructure and deployment patterns for real ML systems
