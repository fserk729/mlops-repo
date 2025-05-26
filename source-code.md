This file is a merged representation of the entire codebase, combined into a single document by Repomix.

# File Summary

## Purpose
This file contains a packed representation of the entire repository's contents.
It is designed to be easily consumable by AI systems for analysis, code review,
or other automated processes.

## File Format
The content is organized as follows:
1. This summary section
2. Repository information
3. Directory structure
4. Repository files (if enabled)
4. Multiple file entries, each consisting of:
  a. A header with the file path (## File: path/to/file)
  b. The full contents of the file in a code block

## Usage Guidelines
- This file should be treated as read-only. Any changes should be made to the
  original repository files, not this packed version.
- When processing this file, use the file path to distinguish
  between different files in the repository.
- Be aware that this file may contain sensitive information. Handle it with
  the same level of security as you would the original repository.

## Notes
- Some files may have been excluded based on .gitignore rules and Repomix's configuration
- Binary files are not included in this packed representation. Please refer to the Repository Structure section for a complete list of file paths, including binary files
- Files matching patterns in .gitignore are excluded
- Files matching default ignore patterns are excluded
- Files are sorted by Git change count (files with more changes are at the bottom)

## Additional Info

# Directory Structure
```
.github/
  workflows/
    tf-infra-cicd-dev.yml
docs/
  mlops-solution-designs.drawio
mlops-course-01/
  terraform/
    provider.tf
    s3_bucket.tf
  README.md
mlops-course-02/
  terraform/
    backends/
      dev.conf
    environments/
      dev.tfvars
    modules/
      s3-bucket/
        locals.tf
        main.tf
        outputs.tf
        variables.tf
      README.md
    provider.tf
    s3_buckets.tf
    variables.tf
  README.md
mlops-course-03/
  src/
    .dvc/
      .gitignore
      config
    pipelines/
      clean.py
      ingest.py
      predict.py
      train.py
    .dvcignore
    .gitignore
    config.yml
    data.dvc
    main.py
    requirements.txt
  terraform/
    backends/
      dev.conf
    environments/
      dev.tfvars
    modules/
      s3-bucket/
        locals.tf
        main.tf
        outputs.tf
        variables.tf
      README.md
    provider.tf
    s3_buckets.tf
    variables.tf
.gitignore
README.md
```

# Files

## File: mlops-course-01/terraform/provider.tf
````hcl
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">=5.97"
    }
  }
}

provider "aws" {
  region = "eu-north-1"
}
````

## File: mlops-course-01/terraform/s3_bucket.tf
````hcl
resource "aws_s3_bucket" "example" {
  bucket = "my-tf-test-d9237282392372dsdsd8"
}
````

## File: mlops-course-02/terraform/modules/s3-bucket/locals.tf
````hcl
locals {
  # name = join(var.delimiter, [var.prefix, var.name])
}
````

## File: mlops-course-02/terraform/modules/s3-bucket/main.tf
````hcl
resource "aws_s3_bucket" "s3" {
  bucket = var.bucket
  tags   = var.tags
}
````

## File: mlops-course-02/terraform/modules/s3-bucket/outputs.tf
````hcl
output "data" {
  description = "S3 Bucket object"
  value       = aws_s3_bucket.s3
}
````

## File: mlops-course-02/terraform/modules/s3-bucket/variables.tf
````hcl
variable "bucket" {
  description = "(Optional, Forces new resource) The name of the bucket. If omitted, Terraform will assign a random, unique name."
  type        = string
  default     = null
}

variable "tags" {
  type        = map(string)
  description = "Map of tags to attach to resource."
}
````

## File: mlops-course-02/terraform/modules/README.md
````markdown
# Terraform AWS S3 Bucket Module

This module provisions an [AWS S3 Bucket](https://docs.aws.amazon.com/s3/index.html) with customizable name and tags.

It is designed for reuse in multi-environment Terraform projects and supports integration into larger infrastructure-as-code workflows.

---

## Features

- Create an S3 bucket with a specified name
- Apply custom tags (e.g., environment, purpose)
- Supports use with `for_each` to manage multiple buckets dynamically

---

## Usage

```hcl
module "s3_bucket" {
  source = "./modules/s3-bucket"

  bucket = "my-bucket-name"
  tags   = {
    environment = "dev"
  }
}
````

## File: mlops-course-02/terraform/provider.tf
````hcl
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">=5.97"
    }
  }

  backend "s3" {}
}

provider "aws" {
  region = var.aws_region
}
````

## File: mlops-course-02/terraform/s3_buckets.tf
````hcl
module "s3_bucket" {
  for_each = { for s3 in var.s3_buckets : s3.key => s3 }
  source   = "./modules/s3-bucket"

  bucket = join(var.delimiter, [each.value.key, var.environment])
  tags   = merge(try(each.value.tags, {}), { environment = var.environment })
}
````

## File: mlops-course-03/src/pipelines/clean.py
````python
import numpy as np
from sklearn.impute import SimpleImputer

class Cleaner:
    def __init__(self):
        self.imputer = SimpleImputer(strategy='most_frequent', missing_values=np.nan)
        
        
    def clean_data(self, data):
        data.drop(['id','SalesChannelID','VehicleAge','DaysSinceCreated'], axis=1, inplace=True)
        
        data['AnnualPremium'] = data['AnnualPremium'].str.replace('£', '').str.replace(',', '').astype(float)
            
        for col in ['Gender', 'RegionID']:
             data[col] = self.imputer.fit_transform(data[[col]]).flatten()
             
        data['Age'] = data['Age'].fillna(data['Age'].median())
        data['HasDrivingLicense']= data['HasDrivingLicense'].fillna(1)
        data['Switch'] = data['Switch'].fillna(-1)
        data['PastAccident'] = data['PastAccident'].fillna("Unknown", inplace=False)
        
        Q1 = data['AnnualPremium'].quantile(0.25)
        Q3 = data['AnnualPremium'].quantile(0.75)
        IQR = Q3 - Q1
        upper_bound = Q3 + 1.5 * IQR
        data = data[data['AnnualPremium'] <= upper_bound]
        
        return data
````

## File: mlops-course-03/src/pipelines/ingest.py
````python
import pandas as pd
import yaml

class Ingestion:
    def __init__(self):
        self.config = self.load_config()

    def load_config(self):
        with open("config.yml", "r") as file:
            return yaml.safe_load(file)

    def load_data(self):
        train_data_path = self.config['data']['train_path']
        test_data_path = self.config['data']['test_path']
        train_data = pd.read_csv(train_data_path)
        test_data = pd.read_csv(test_data_path)
        return train_data, test_data
````

## File: mlops-course-03/src/pipelines/predict.py
````python
import os
import joblib
from sklearn.metrics import accuracy_score, classification_report, roc_auc_score

class Predictor:
    def __init__(self):
        self.model_path = self.load_config()['model']['store_path']
        self.pipeline = self.load_model()

    def load_config(self):
        import yaml
        with open('config.yml', 'r') as config_file:
            return yaml.safe_load(config_file)
        
    def load_model(self):
        model_file_path = os.path.join(self.model_path, 'model.pkl')
        return joblib.load(model_file_path)

    def feature_target_separator(self, data):
        X = data.iloc[:, :-1]
        y = data.iloc[:, -1]
        return X, y

    def evaluate_model(self, X_test, y_test):
        y_pred = self.pipeline.predict(X_test)
        accuracy = accuracy_score(y_test, y_pred)
        class_report = classification_report(y_test, y_pred)
        roc_auc = roc_auc_score(y_test, y_pred)
        return accuracy, class_report, roc_auc
````

## File: mlops-course-03/src/pipelines/train.py
````python
import os
import joblib
import yaml
from sklearn.preprocessing import StandardScaler, OneHotEncoder, MinMaxScaler
from sklearn.compose import ColumnTransformer
from imblearn.over_sampling import SMOTE
from imblearn.pipeline import Pipeline 
from sklearn.ensemble import RandomForestClassifier, GradientBoostingClassifier
from sklearn.tree import DecisionTreeClassifier

class Trainer:
    def __init__(self):
        self.config = self.load_config()
        self.model_name = self.config['model']['name']
        self.model_params = self.config['model']['params']
        self.model_path = self.config['model']['store_path']
        self.pipeline = self.create_pipeline()

    def load_config(self):
        with open('config.yml', 'r') as config_file:
            return yaml.safe_load(config_file)
        
    def create_pipeline(self):
        preprocessor = ColumnTransformer(transformers=[
            ('minmax', MinMaxScaler(), ['AnnualPremium']),
            ('standardize', StandardScaler(), ['Age','RegionID']),
            ('onehot', OneHotEncoder(handle_unknown='ignore'), ['Gender', 'PastAccident']),
        ])
        
        smote = SMOTE(sampling_strategy=1.0)
        
        model_map = {
            'RandomForestClassifier': RandomForestClassifier,
            'DecisionTreeClassifier': DecisionTreeClassifier,
            'GradientBoostingClassifier': GradientBoostingClassifier
        }
    
        model_class = model_map[self.model_name]
        model = model_class(**self.model_params)

        pipeline = Pipeline([
            ('preprocessor', preprocessor),
            ('smote', smote),
            ('model', model)
        ])

        return pipeline

    def feature_target_separator(self, data):
        X = data.iloc[:, :-1]
        y = data.iloc[:, -1]
        return X, y

    def train_model(self, X_train, y_train):
        self.pipeline.fit(X_train, y_train)

    def save_model(self):
        model_file_path = os.path.join(self.model_path, 'model.pkl')
        joblib.dump(self.pipeline, model_file_path)
````

## File: mlops-course-03/src/main.py
````python
import logging
from pipelines.ingest import Ingestion
from pipelines.clean import Cleaner
from pipelines.train import Trainer
from pipelines.predict import Predictor

logging.basicConfig(level=logging.INFO,format='%(asctime)s:%(levelname)s:%(message)s')

def main():
    # Load data
    ingestion = Ingestion()
    train, test = ingestion.load_data()
    logging.info("Data ingestion completed successfully")

    # Clean data
    cleaner = Cleaner()
    train_data = cleaner.clean_data(train)
    test_data = cleaner.clean_data(test)
    logging.info("Data cleaning completed successfully")

    # Prepare and train model
    trainer = Trainer()
    X_train, y_train = trainer.feature_target_separator(train_data)
    trainer.train_model(X_train, y_train)
    trainer.save_model()
    logging.info("Model training completed successfully")

    # Evaluate model
    predictor = Predictor()
    X_test, y_test = predictor.feature_target_separator(test_data)
    accuracy, class_report, roc_auc_score = predictor.evaluate_model(X_test, y_test)
    logging.info("Model evaluation completed successfully")
    
    # Print evaluation results
    print("\n============= Model Evaluation Results ==============")
    print(f"Model: {trainer.model_name}")
    print(f"Accuracy Score: {accuracy:.4f}, ROC AUC Score: {roc_auc_score:.4f}")
    print(f"\n{class_report}")
    print("=====================================================\n")
    
if __name__ == "__main__":
    main()
````

## File: mlops-course-03/src/requirements.txt
````
dvc==3.59.2
dvc-s3==3.2.0
imbalanced-learn==0.13.0
mlflow==2.22.0
notebook==7.4.2
pandas==2.2.3
scikit-learn==1.6.1
joblib==1.5.0
fastapi==0.115.12
pytest==8.3.5
````

## File: mlops-course-03/terraform/backends/dev.conf
````
bucket  = "tf-remote-backends-ehb"
key     = "terraform-dev.tfstate"
region  = "eu-north-1"
encrypt = true
use_lockfile = true
````

## File: mlops-course-03/terraform/environments/dev.tfvars
````hcl
environment = "dev"
aws_region  = "eu-north-1"


s3_buckets = [
  {
    key  = "mlops-course-ehb-data"
    tags = {}
  }
]
````

## File: mlops-course-03/terraform/modules/s3-bucket/locals.tf
````hcl
locals {
  # name = join(var.delimiter, [var.prefix, var.name])
}
````

## File: mlops-course-03/terraform/modules/s3-bucket/main.tf
````hcl
resource "aws_s3_bucket" "s3" {
  bucket = var.bucket
  tags   = var.tags
}
````

## File: mlops-course-03/terraform/modules/s3-bucket/outputs.tf
````hcl
output "data" {
  description = "S3 Bucket object"
  value       = aws_s3_bucket.s3
}
````

## File: mlops-course-03/terraform/modules/s3-bucket/variables.tf
````hcl
variable "bucket" {
  description = "(Optional, Forces new resource) The name of the bucket. If omitted, Terraform will assign a random, unique name."
  type        = string
  default     = null
}

variable "tags" {
  type        = map(string)
  description = "Map of tags to attach to resource."
}
````

## File: mlops-course-03/terraform/modules/README.md
````markdown
# Terraform AWS S3 Bucket Module

This module provisions an [AWS S3 Bucket](https://docs.aws.amazon.com/s3/index.html) with customizable name and tags.

It is designed for reuse in multi-environment Terraform projects and supports integration into larger infrastructure-as-code workflows.

---

## Features

- Create an S3 bucket with a specified name
- Apply custom tags (e.g., environment, purpose)
- Supports use with `for_each` to manage multiple buckets dynamically

---

## Usage

```hcl
module "s3_bucket" {
  source = "./modules/s3-bucket"

  bucket = "my-bucket-name"
  tags   = {
    environment = "dev"
  }
}
````

## File: mlops-course-03/terraform/provider.tf
````hcl
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">=5.97"
    }
  }

  backend "s3" {}
}

provider "aws" {
  region = var.aws_region
}
````

## File: mlops-course-03/terraform/s3_buckets.tf
````hcl
module "s3_bucket" {
  for_each = { for s3 in var.s3_buckets : s3.key => s3 }
  source   = "./modules/s3-bucket"

  bucket = join(var.delimiter, [each.value.key, var.environment])
  tags   = merge(try(each.value.tags, {}), { environment = var.environment })
}
````

## File: mlops-course-03/terraform/variables.tf
````hcl
variable "aws_region" {
  description = "AWS region"
  default     = "eu-north-1"
}

variable "environment" {
  description = "Specifies the deployment environment of the resources (e.g., dev, tst, acc, prd)"
  type        = string
  default     = "sandbox"
}

variable "delimiter" {
  description = "Resource name delimiter"
  type        = string
  default     = "-"
}

variable "s3_buckets" {
  description = "A list of S3 Buckets"
  type        = list(any)
  default     = []
}
````

## File: .gitignore
````
# Byte-compiled / optimized / DLL files
__pycache__/
*.py[cod]
*$py.class

# C extensions
*.so

# Distribution / packaging
.Python
build/
develop-eggs/
dist/
downloads/
eggs/
.eggs/
lib/
lib64/
parts/
sdist/
var/
wheels/
share/python-wheels/
*.egg-info/
.installed.cfg
*.egg
MANIFEST

# PyInstaller
#  Usually these files are written by a python script from a template
#  before PyInstaller builds the exe, so as to inject date/other infos into it.
*.manifest
*.spec

# Installer logs
pip-log.txt
pip-delete-this-directory.txt

# Unit test / coverage reports
htmlcov/
.tox/
.nox/
.coverage
.coverage.*
.cache
nosetests.xml
coverage.xml
*.cover
*.py,cover
.hypothesis/
.pytest_cache/
cover/

# Translations
*.mo
*.pot

# Django stuff:
*.log
local_settings.py
db.sqlite3
db.sqlite3-journal

# Flask stuff:
instance/
.webassets-cache

# Scrapy stuff:
.scrapy

# Sphinx documentation
docs/_build/

# PyBuilder
.pybuilder/
target/

# Jupyter Notebook
.ipynb_checkpoints

# IPython
profile_default/
ipython_config.py

# pyenv
#   For a library or package, you might want to ignore these files since the code is
#   intended to run in multiple environments; otherwise, check them in:
# .python-version

# pipenv
#   According to pypa/pipenv#598, it is recommended to include Pipfile.lock in version control.
#   However, in case of collaboration, if having platform-specific dependencies or dependencies
#   having no cross-platform support, pipenv may install dependencies that don't work, or not
#   install all needed dependencies.
#Pipfile.lock

# UV
#   Similar to Pipfile.lock, it is generally recommended to include uv.lock in version control.
#   This is especially recommended for binary packages to ensure reproducibility, and is more
#   commonly ignored for libraries.
#uv.lock

# poetry
#   Similar to Pipfile.lock, it is generally recommended to include poetry.lock in version control.
#   This is especially recommended for binary packages to ensure reproducibility, and is more
#   commonly ignored for libraries.
#   https://python-poetry.org/docs/basic-usage/#commit-your-poetrylock-file-to-version-control
#poetry.lock

# pdm
#   Similar to Pipfile.lock, it is generally recommended to include pdm.lock in version control.
#pdm.lock
#   pdm stores project-wide configurations in .pdm.toml, but it is recommended to not include it
#   in version control.
#   https://pdm.fming.dev/latest/usage/project/#working-with-version-control
.pdm.toml
.pdm-python
.pdm-build/

# PEP 582; used by e.g. github.com/David-OConnor/pyflow and github.com/pdm-project/pdm
__pypackages__/

# Celery stuff
celerybeat-schedule
celerybeat.pid

# SageMath parsed files
*.sage.py

# Environments
.env
.venv
env/
venv/
ENV/
env.bak/
venv.bak/

# Spyder project settings
.spyderproject
.spyproject

# Rope project settings
.ropeproject

# mkdocs documentation
/site

# mypy
.mypy_cache/
.dmypy.json
dmypy.json

# Pyre type checker
.pyre/

# pytype static type analyzer
.pytype/

# Cython debug symbols
cython_debug/

# PyCharm
#  JetBrains specific template is maintained in a separate JetBrains.gitignore that can
#  be found at https://github.com/github/gitignore/blob/main/Global/JetBrains.gitignore
#  and can be added to the global gitignore or merged into this file.  For a more nuclear
#  option (not recommended) you can uncomment the following to ignore the entire idea folder.
#.idea/

# Ruff stuff:
.ruff_cache/

# PyPI configuration file
.pypirc
````

## File: mlops-course-01/README.md
````markdown
# AWS Infrastructure Setup with Terraform for Local Development

This guide walks you through setting up basic AWS infrastructure using Terraform for local development. You'll learn how to provision an AWS S3 bucket as a demonstration of Terraform's infrastructure-as-code capabilities.
![terraform-aws-setup-maturity-level-0-design](assets/tf-aws-setup-maturity-lvl-0.png)

## Prerequisites

* [Terraform](https://developer.hashicorp.com/terraform/downloads)
* [AWS CLI](https://aws.amazon.com/cli/) configured (`aws configure`)
* Access Key under root account

## 1. Configure AWS Credentials
Set up your AWS credentials as environment variables to avoid hardcoding sensitive information:
```bash
export AWS_ACCESS_KEY_ID=""
export AWS_SECRET_ACCESS_KEY=""
```
For more secure credential management: https://registry.terraform.io/providers/hashicorp/aws/latest/docs

## 2. Project Structure
Organize your infrastructure code for clarity and scalability:
```
mlops-course-01/
├── assets/
├── docs/
├── src/
├── terraform/
│   ├── provider.tf
│   └── s3.tf
└── README.md
```
All Terraform files live under the `terraform/` folder.

## 3. Terraform Configuration
Specifies AWS as provider, enforces version, and sets the region.

`provider.tf`
```hcl
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">=5.97"
    }
  }
}

provider "aws" {
  region = "eu-north-1"
}
```
Creates an S3 bucket with a unique name.

`s3.tf`
```hcl
resource "aws_s3_bucket" "example" {
  bucket = "my-tf-test-d9237282392372dsdsd8"
}
```

### 4. Apply Terraform Configuration using Terraform CLI
```bash
terraform init                # Download providers and initialize the project
terraform validate            # Check configuration for errors
terraform fmt --recursive     # Format files for readability
terraform plan                # Preview what will be created
terraform apply               # Create the resources
terraform destroy             # Remove all managed resources
```
````

## File: mlops-course-02/terraform/backends/dev.conf
````
bucket  = "tf-remote-backends-ehb"
key     = "terraform-dev.tfstate"
region  = "eu-north-1"
encrypt = true
use_lockfile = true
````

## File: mlops-course-02/terraform/environments/dev.tfvars
````hcl
environment = "dev"
aws_region  = "eu-north-1"


s3_buckets = [
  {
    key  = "mlops-course-ehb-data"
    tags = {}
  }
]
````

## File: mlops-course-02/terraform/variables.tf
````hcl
variable "aws_region" {
  description = "AWS region"
  default     = "eu-north-1"
}

variable "environment" {
  description = "Specifies the deployment environment of the resources (e.g., dev, tst, acc, prd)"
  type        = string
  default     = "sandbox"
}

variable "delimiter" {
  description = "Resource name delimiter"
  type        = string
  default     = "-"
}

variable "s3_buckets" {
  description = "A list of S3 Buckets"
  type        = list(any)
  default     = []
}
````

## File: mlops-course-03/src/config.yml
````yaml
data: 
  train_path: data/train.csv
  test_path: data/test.csv

train:
  test_size: 0.2
  random_state: 42
  shuffle: true

model:
  # name: DecisionTreeClassifier
  # params:
  #   criterion: entropy
  #   max_depth: null
  # store_path: models/

  name: GradientBoostingClassifier
  params:
    max_depth: null
    n_estimators: 10
  store_path: models/

  # name: RandomForestClassifier
  # params:
  #   n_estimators: 50
  #   max_depth: 10
  #   random_state: 42
  # store_path: models/
````

## File: README.md
````markdown
# MLOps Course 
This repository provides practical, hands-on blueprints and demonstrates DevOps practices for MLOps projects, showing a progression in maturity levels from basic local development to automated CI/CD pipelines.
````

## File: .github/workflows/tf-infra-cicd-dev.yml
````yaml
name: tf-infra-cicd-dev

# Controls when the workflow will run
on:
  # Triggers the workflow on push or pull request events but only for the "main" branch
  pull_request:
    branches: [ "main" ]

  # Allows you to run this workflow manually from the Actions tab
  workflow_dispatch:

jobs:
  terraform-validate-plan-apply:
    runs-on: ubuntu-latest
    defaults:
      run:
        working-directory: mlops-course-02/terraform

    steps:
      - name: Checkout repository
        uses: actions/checkout@v4

      - name: Setup Terraform
        uses: hashicorp/setup-terraform@v3

      - name: Configure AWS credentials
        uses: aws-actions/configure-aws-credentials@v4
        with:
          aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
          aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
          aws-region: eu-north-1

      - name: Terraform Format
        run: terraform fmt -check
        continue-on-error: true

      - name: Terraform Init
        run: terraform init --backend-config='backends/dev.conf'

      - name: Terraform Validate
        run: terraform validate -no-color

      - name: Terraform Plan
        run: terraform plan -no-color --var-file='environments/dev.tfvars'

      - name: Terraform Apply
        run: terraform apply --var-file='environments/dev.tfvars' -auto-approve
````

## File: docs/mlops-solution-designs.drawio
````
<mxfile host="65bd71144e" scale="1" border="20">
    <diagram name="mlops-solution-design" id="Dg3Lw9tu1t9dLLiXHJVm">
        <mxGraphModel dx="978" dy="325" grid="0" gridSize="10" guides="1" tooltips="1" connect="1" arrows="1" fold="1" page="0" pageScale="1" pageWidth="1100" pageHeight="850" background="#ffffff" math="0" shadow="0">
            <root>
                <mxCell id="sOep82PyB1NGChh_XDzF-0"/>
                <mxCell id="sOep82PyB1NGChh_XDzF-1" parent="sOep82PyB1NGChh_XDzF-0"/>
                <mxCell id="sOep82PyB1NGChh_XDzF-2" value="&lt;span&gt;&amp;nbsp; &amp;nbsp; &amp;nbsp; GitHub&lt;/span&gt;" style="fillColor=none;strokeColor=#5A6C86;dashed=1;verticalAlign=top;fontStyle=0;fontColor=#5A6C86;whiteSpace=wrap;html=1;align=left;" vertex="1" parent="sOep82PyB1NGChh_XDzF-1">
                    <mxGeometry x="225" y="471" width="432" height="317" as="geometry"/>
                </mxCell>
                <mxCell id="sOep82PyB1NGChh_XDzF-3" value="AWS Account" style="points=[[0,0],[0.25,0],[0.5,0],[0.75,0],[1,0],[1,0.25],[1,0.5],[1,0.75],[1,1],[0.75,1],[0.5,1],[0.25,1],[0,1],[0,0.75],[0,0.5],[0,0.25]];outlineConnect=0;gradientColor=none;html=1;whiteSpace=wrap;fontSize=12;fontStyle=0;container=1;pointerEvents=0;collapsible=0;recursiveResize=0;shape=mxgraph.aws4.group;grIcon=mxgraph.aws4.group_account;strokeColor=#CD2264;fillColor=none;verticalAlign=top;align=left;spacingLeft=30;fontColor=#CD2264;dashed=0;" vertex="1" parent="sOep82PyB1NGChh_XDzF-1">
                    <mxGeometry x="767" y="407" width="763" height="528" as="geometry"/>
                </mxCell>
                <mxCell id="sOep82PyB1NGChh_XDzF-4" value="eu-north-1" style="points=[[0,0],[0.25,0],[0.5,0],[0.75,0],[1,0],[1,0.25],[1,0.5],[1,0.75],[1,1],[0.75,1],[0.5,1],[0.25,1],[0,1],[0,0.75],[0,0.5],[0,0.25]];outlineConnect=0;gradientColor=none;html=1;whiteSpace=wrap;fontSize=12;fontStyle=0;container=1;pointerEvents=0;collapsible=0;recursiveResize=0;shape=mxgraph.aws4.group;grIcon=mxgraph.aws4.group_region;strokeColor=#00A4A6;fillColor=none;verticalAlign=top;align=left;spacingLeft=30;fontColor=#147EBA;dashed=1;" vertex="1" parent="sOep82PyB1NGChh_XDzF-3">
                    <mxGeometry x="30" y="166" width="640" height="305" as="geometry"/>
                </mxCell>
                <mxCell id="sOep82PyB1NGChh_XDzF-5" value="S3 Backend" style="fillColor=none;strokeColor=#5A6C86;dashed=1;verticalAlign=top;fontStyle=0;fontColor=#5A6C86;whiteSpace=wrap;html=1;" vertex="1" parent="sOep82PyB1NGChh_XDzF-4">
                    <mxGeometry x="29" y="46" width="335" height="192" as="geometry"/>
                </mxCell>
                <mxCell id="sOep82PyB1NGChh_XDzF-6" style="edgeStyle=none;html=1;fontStyle=0" edge="1" parent="sOep82PyB1NGChh_XDzF-4" source="sOep82PyB1NGChh_XDzF-7" target="sOep82PyB1NGChh_XDzF-8">
                    <mxGeometry relative="1" as="geometry"/>
                </mxCell>
                <mxCell id="sOep82PyB1NGChh_XDzF-7" value="&lt;div&gt;&lt;span style=&quot;color: rgb(63, 63, 63); font-family: Helvetica; font-size: 12px; font-style: normal; font-variant-ligatures: normal; font-variant-caps: normal; font-weight: 400; letter-spacing: normal; orphans: 2; text-align: center; text-indent: 0px; text-transform: none; widows: 2; word-spacing: 0px; -webkit-text-stroke-width: 0px; white-space: nowrap; background-color: rgb(251, 251, 251); text-decoration-thickness: initial; text-decoration-style: initial; text-decoration-color: initial; float: none; display: inline !important;&quot;&gt;S3 Bucket&lt;/span&gt;&lt;/div&gt;&lt;span style=&quot;color: rgb(63, 63, 63); font-family: Helvetica; font-size: 12px; font-style: normal; font-variant-ligatures: normal; font-variant-caps: normal; font-weight: 400; letter-spacing: normal; orphans: 2; text-align: center; text-indent: 0px; text-transform: none; widows: 2; word-spacing: 0px; -webkit-text-stroke-width: 0px; white-space: nowrap; background-color: rgb(251, 251, 251); text-decoration-thickness: initial; text-decoration-style: initial; text-decoration-color: initial; float: none; display: inline !important;&quot;&gt;tf-remote-backends-ehb&lt;/span&gt;" style="sketch=0;outlineConnect=0;fontColor=#232F3E;gradientColor=none;fillColor=#7AA116;strokeColor=none;dashed=0;verticalLabelPosition=bottom;verticalAlign=top;align=center;html=1;fontSize=12;fontStyle=0;aspect=fixed;pointerEvents=1;shape=mxgraph.aws4.bucket;" vertex="1" parent="sOep82PyB1NGChh_XDzF-4">
                    <mxGeometry x="91.73" y="66" width="36.54" height="38" as="geometry"/>
                </mxCell>
                <mxCell id="sOep82PyB1NGChh_XDzF-8" value="terraform.tfstate" style="sketch=0;outlineConnect=0;fontColor=#232F3E;gradientColor=none;fillColor=#232F3D;strokeColor=none;dashed=0;verticalLabelPosition=bottom;verticalAlign=top;align=center;html=1;fontSize=12;fontStyle=0;aspect=fixed;pointerEvents=1;shape=mxgraph.aws4.document;" vertex="1" parent="sOep82PyB1NGChh_XDzF-4">
                    <mxGeometry x="95.01999999999998" y="168" width="29.96" height="41" as="geometry"/>
                </mxCell>
                <mxCell id="sOep82PyB1NGChh_XDzF-9" value="Encryption" style="sketch=0;outlineConnect=0;gradientColor=none;fillColor=#DD344C;strokeColor=none;dashed=0;verticalLabelPosition=bottom;verticalAlign=top;align=center;aspect=fixed;pointerEvents=1;shape=mxgraph.aws4.data_encryption_key;html=1;" vertex="1" parent="sOep82PyB1NGChh_XDzF-4">
                    <mxGeometry x="317" y="49" width="26.23" height="33" as="geometry"/>
                </mxCell>
                <mxCell id="sOep82PyB1NGChh_XDzF-10" value="Versioning" style="image;aspect=fixed;points=[];align=center;image=img/lib/azure2/general/Versions.svg;html=1;" vertex="1" parent="sOep82PyB1NGChh_XDzF-4">
                    <mxGeometry x="314.16000000000025" y="113.5" width="27.9" height="27" as="geometry"/>
                </mxCell>
                <mxCell id="sOep82PyB1NGChh_XDzF-11" value="State Lock" style="html=1;verticalLabelPosition=bottom;align=center;labelBackgroundColor=#ffffff;verticalAlign=top;strokeWidth=2;strokeColor=#0080F0;shadow=0;dashed=0;shape=mxgraph.ios7.icons.locked;" vertex="1" parent="sOep82PyB1NGChh_XDzF-4">
                    <mxGeometry x="316" y="171" width="24" height="30" as="geometry"/>
                </mxCell>
                <mxCell id="sOep82PyB1NGChh_XDzF-12" value="&lt;div&gt;&lt;span style=&quot;color: rgb(63, 63, 63); font-family: Helvetica; font-size: 12px; font-style: normal; font-variant-ligatures: normal; font-variant-caps: normal; font-weight: 400; letter-spacing: normal; orphans: 2; text-align: center; text-indent: 0px; text-transform: none; widows: 2; word-spacing: 0px; -webkit-text-stroke-width: 0px; white-space: nowrap; background-color: rgb(251, 251, 251); text-decoration-thickness: initial; text-decoration-style: initial; text-decoration-color: initial; float: none; display: inline !important;&quot;&gt;S3 Bucket&lt;/span&gt;&lt;/div&gt;&lt;div&gt;&lt;span style=&quot;orphans: 2; text-align: center; text-indent: 0px; widows: 2; background-color: rgb(251, 251, 251); text-decoration-thickness: initial; text-decoration-style: initial; text-decoration-color: initial; float: none; display: inline !important; color: rgb(63, 63, 63);&quot;&gt;mlops-course-ehb-data-dev&lt;/span&gt;&lt;/div&gt;" style="sketch=0;outlineConnect=0;fontColor=#232F3E;gradientColor=none;fillColor=#7AA116;strokeColor=none;dashed=0;verticalLabelPosition=bottom;verticalAlign=top;align=center;html=1;fontSize=12;fontStyle=0;aspect=fixed;pointerEvents=1;shape=mxgraph.aws4.bucket;" vertex="1" parent="sOep82PyB1NGChh_XDzF-4">
                    <mxGeometry x="480" y="66" width="36.54" height="38" as="geometry"/>
                </mxCell>
                <mxCell id="sOep82PyB1NGChh_XDzF-13" style="edgeStyle=none;html=1;fontStyle=0" edge="1" parent="sOep82PyB1NGChh_XDzF-3" source="sOep82PyB1NGChh_XDzF-14" target="sOep82PyB1NGChh_XDzF-16">
                    <mxGeometry relative="1" as="geometry"/>
                </mxCell>
                <mxCell id="sOep82PyB1NGChh_XDzF-14" value="IAM User&lt;div&gt;Terraform User&lt;/div&gt;" style="sketch=0;outlineConnect=0;fontColor=#232F3E;gradientColor=none;fillColor=#DD344C;strokeColor=none;dashed=0;verticalLabelPosition=bottom;verticalAlign=top;align=center;html=1;fontSize=12;fontStyle=0;aspect=fixed;pointerEvents=1;shape=mxgraph.aws4.role;" vertex="1" parent="sOep82PyB1NGChh_XDzF-3">
                    <mxGeometry x="93" y="64" width="33.68" height="19" as="geometry"/>
                </mxCell>
                <mxCell id="sOep82PyB1NGChh_XDzF-15" style="edgeStyle=none;html=1;fontStyle=0" edge="1" parent="sOep82PyB1NGChh_XDzF-3" source="sOep82PyB1NGChh_XDzF-16" target="sOep82PyB1NGChh_XDzF-5">
                    <mxGeometry relative="1" as="geometry"/>
                </mxCell>
                <mxCell id="sOep82PyB1NGChh_XDzF-16" value="&lt;div&gt;IAM Role&lt;/div&gt;Administrative Access&amp;nbsp;" style="sketch=0;outlineConnect=0;fontColor=#232F3E;gradientColor=none;fillColor=#DD344C;strokeColor=none;dashed=0;verticalLabelPosition=bottom;verticalAlign=top;align=center;html=1;fontSize=12;fontStyle=0;aspect=fixed;pointerEvents=1;shape=mxgraph.aws4.long_term_security_credential;" vertex="1" parent="sOep82PyB1NGChh_XDzF-3">
                    <mxGeometry x="212" y="58" width="35.04" height="31" as="geometry"/>
                </mxCell>
                <mxCell id="sOep82PyB1NGChh_XDzF-17" style="edgeStyle=none;html=1;entryX=0;entryY=0.5;entryDx=0;entryDy=0;fontStyle=0" edge="1" parent="sOep82PyB1NGChh_XDzF-1" source="sOep82PyB1NGChh_XDzF-18" target="sOep82PyB1NGChh_XDzF-3">
                    <mxGeometry relative="1" as="geometry"/>
                </mxCell>
                <mxCell id="sOep82PyB1NGChh_XDzF-18" value="Terraform CLI" style="shape=image;verticalLabelPosition=bottom;verticalAlign=top;imageAspect=0;aspect=fixed;image=data:image/svg+xml,PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHZpZXdCb3g9IjAgNy41IDUwIDU3IiBoZWlnaHQ9IjU3IiB3aWR0aD0iNTAiIGlkPSJMb2dvcyI+PGRlZnM+PHN0eWxlPi5jbHMtMXtmaWxsOiM3YjQyYmM7ZmlsbC1ydWxlOmV2ZW5vZGQ7c3Ryb2tlLXdpZHRoOjBweDt9PC9zdHlsZT48L2RlZnM+PHBhdGggZD0iTTE3LjMsMTcuNWwxNS41LDl2MThsLTE1LjUtOXYtMThaIiBjbGFzcz0iY2xzLTEiLz48cGF0aCBkPSJNMzQuNSwyNi41djE4bDE1LjUtOXYtMThsLTE1LjUsOVoiIGNsYXNzPSJjbHMtMSIvPjxwYXRoIGQ9Ik0wLDcuNXYxOGwxNS41LDl2LTE4TDAsNy41WiIgY2xhc3M9ImNscy0xIi8+PHBhdGggZD0iTTE3LjMsNTUuNWwxNS41LDl2LTE4bC0xNS41LTl2MThaIiBjbGFzcz0iY2xzLTEiLz48L3N2Zz4=;" vertex="1" parent="sOep82PyB1NGChh_XDzF-1">
                    <mxGeometry x="574" y="649" width="42.11" height="48" as="geometry"/>
                </mxCell>
                <mxCell id="sOep82PyB1NGChh_XDzF-19" style="edgeStyle=none;html=1;entryX=0;entryY=0.5;entryDx=0;entryDy=0;labelPosition=center;verticalLabelPosition=top;align=center;verticalAlign=bottom;fontStyle=0" edge="1" parent="sOep82PyB1NGChh_XDzF-1" target="sOep82PyB1NGChh_XDzF-2">
                    <mxGeometry relative="1" as="geometry">
                        <mxPoint x="111" y="628" as="sourcePoint"/>
                    </mxGeometry>
                </mxCell>
                <mxCell id="sOep82PyB1NGChh_XDzF-20" value="Commit &amp;amp; Push" style="edgeLabel;html=1;align=center;verticalAlign=bottom;resizable=0;points=[];labelPosition=center;verticalLabelPosition=top;" vertex="1" connectable="0" parent="sOep82PyB1NGChh_XDzF-19">
                    <mxGeometry x="0.0711" relative="1" as="geometry">
                        <mxPoint as="offset"/>
                    </mxGeometry>
                </mxCell>
                <mxCell id="sOep82PyB1NGChh_XDzF-21" value="Developer X" style="sketch=0;outlineConnect=0;fontColor=#232F3E;gradientColor=none;fillColor=#232F3D;strokeColor=none;dashed=0;verticalLabelPosition=bottom;verticalAlign=top;align=center;html=1;fontSize=12;fontStyle=0;aspect=fixed;pointerEvents=1;shape=mxgraph.aws4.user;" vertex="1" parent="sOep82PyB1NGChh_XDzF-1">
                    <mxGeometry x="74" y="608" width="39" height="39" as="geometry"/>
                </mxCell>
                <mxCell id="sOep82PyB1NGChh_XDzF-22" value="Terraform&amp;nbsp;&lt;span style=&quot;background-color: transparent;&quot;&gt;Files&lt;/span&gt;" style="sketch=0;outlineConnect=0;fontColor=#232F3E;gradientColor=none;fillColor=#232F3D;strokeColor=none;dashed=0;verticalLabelPosition=bottom;verticalAlign=top;align=center;html=1;fontSize=12;fontStyle=0;aspect=fixed;pointerEvents=1;shape=mxgraph.aws4.documents3;" vertex="1" parent="sOep82PyB1NGChh_XDzF-1">
                    <mxGeometry x="284" y="663" width="30.69" height="42" as="geometry"/>
                </mxCell>
                <mxCell id="sOep82PyB1NGChh_XDzF-23" style="edgeStyle=none;html=1;exitX=1;exitY=0.5;exitDx=0;exitDy=0;exitPerimeter=0;entryX=0;entryY=0.5;entryDx=0;entryDy=0;fontStyle=0" edge="1" parent="sOep82PyB1NGChh_XDzF-1" source="sOep82PyB1NGChh_XDzF-24" target="sOep82PyB1NGChh_XDzF-18">
                    <mxGeometry relative="1" as="geometry"/>
                </mxCell>
                <mxCell id="sOep82PyB1NGChh_XDzF-24" value="AWS CLI&amp;nbsp;&lt;span style=&quot;background-color: transparent;&quot;&gt;&amp;amp;&amp;nbsp;&lt;/span&gt;&lt;div&gt;&lt;span style=&quot;background-color: transparent;&quot;&gt;Access Key&lt;/span&gt;&lt;/div&gt;" style="sketch=0;points=[[0,0,0],[0.25,0,0],[0.5,0,0],[0.75,0,0],[1,0,0],[0,1,0],[0.25,1,0],[0.5,1,0],[0.75,1,0],[1,1,0],[0,0.25,0],[0,0.5,0],[0,0.75,0],[1,0.25,0],[1,0.5,0],[1,0.75,0]];points=[[0,0,0],[0.25,0,0],[0.5,0,0],[0.75,0,0],[1,0,0],[0,1,0],[0.25,1,0],[0.5,1,0],[0.75,1,0],[1,1,0],[0,0.25,0],[0,0.5,0],[0,0.75,0],[1,0.25,0],[1,0.5,0],[1,0.75,0]];outlineConnect=0;fontColor=#232F3E;fillColor=#E7157B;strokeColor=#ffffff;dashed=0;verticalLabelPosition=bottom;verticalAlign=top;align=center;html=1;fontSize=12;fontStyle=0;aspect=fixed;shape=mxgraph.aws4.resourceIcon;resIcon=mxgraph.aws4.command_line_interface;" vertex="1" parent="sOep82PyB1NGChh_XDzF-1">
                    <mxGeometry x="477" y="656" width="35" height="35" as="geometry"/>
                </mxCell>
                <mxCell id="sOep82PyB1NGChh_XDzF-25" style="shape=image;editableCssRules=.*;image=data:image/svg+xml,PHN2ZyB2aWV3Qm94PSIwIDAgMjQgMjQiIHhtbG5zPSJodHRwOi8vd3d3LnczLm9yZy8yMDAwL3N2ZyI+PHN0eWxlPip7ZmlsbDojMTgxNzE3fTwvc3R5bGU+PHBhdGggZD0iTTEyIC4yOTdjLTYuNjMgMC0xMiA1LjM3My0xMiAxMiAwIDUuMzAzIDMuNDM4IDkuOCA4LjIwNSAxMS4zODUuNi4xMTMuODItLjI1OC44Mi0uNTc3IDAtLjI4NS0uMDEtMS4wNC0uMDE1LTIuMDQtMy4zMzguNzI0LTQuMDQyLTEuNjEtNC4wNDItMS42MUM0LjQyMiAxOC4wNyAzLjYzMyAxNy43IDMuNjMzIDE3LjdjLTEuMDg3LS43NDQuMDg0LS43MjkuMDg0LS43MjkgMS4yMDUuMDg0IDEuODM4IDEuMjM2IDEuODM4IDEuMjM2IDEuMDcgMS44MzUgMi44MDkgMS4zMDUgMy40OTUuOTk4LjEwOC0uNzc2LjQxNy0xLjMwNS43Ni0xLjYwNS0yLjY2NS0uMy01LjQ2Ni0xLjMzMi01LjQ2Ni01LjkzIDAtMS4zMS40NjUtMi4zOCAxLjIzNS0zLjIyLS4xMzUtLjMwMy0uNTQtMS41MjMuMTA1LTMuMTc2IDAgMCAxLjAwNS0uMzIyIDMuMyAxLjIzLjk2LS4yNjcgMS45OC0uMzk5IDMtLjQwNSAxLjAyLjAwNiAyLjA0LjEzOCAzIC40MDUgMi4yOC0xLjU1MiAzLjI4NS0xLjIzIDMuMjg1LTEuMjMuNjQ1IDEuNjUzLjI0IDIuODczLjEyIDMuMTc2Ljc2NS44NCAxLjIzIDEuOTEgMS4yMyAzLjIyIDAgNC42MS0yLjgwNSA1LjYyNS01LjQ3NSA1LjkyLjQyLjM2LjgxIDEuMDk2LjgxIDIuMjIgMCAxLjYwNi0uMDE1IDIuODk2LS4wMTUgMy4yODYgMCAuMzE1LjIxLjY5LjgyNS41N0MyMC41NjUgMjIuMDkyIDI0IDE3LjU5MiAyNCAxMi4yOTdjMC02LjYyNy01LjM3My0xMi0xMi0xMiIvPjwvc3ZnPg==;" vertex="1" parent="sOep82PyB1NGChh_XDzF-1">
                    <mxGeometry x="205" y="475" width="62" height="15" as="geometry"/>
                </mxCell>
                <mxCell id="sOep82PyB1NGChh_XDzF-26" value="GitHub Actions" style="shape=image;editableCssRules=.*;image=data:image/svg+xml,PHN2ZyB2aWV3Qm94PSIwIDAgMjQgMjQiIHhtbG5zPSJodHRwOi8vd3d3LnczLm9yZy8yMDAwL3N2ZyI+PHN0eWxlPip7ZmlsbDojMjA4OEZGfTwvc3R5bGU+PHBhdGggZD0iTTEwLjk4NCAxMy44MzZhLjUuNSAwIDAgMS0uMzUzLS4xNDZsLS43NDUtLjc0M2EuNS41IDAgMSAxIC43MDYtLjcwOGwuMzkyLjM5MSAxLjE4MS0xLjE4YS41LjUgMCAwIDEgLjcwOC43MDdsLTEuNTM1IDEuNTMzYS41MDQuNTA0IDAgMCAxLS4zNTQuMTQ2em05LjM1My0uMTQ3bDEuNTM0LTEuNTMyYS41LjUgMCAwIDAtLjcwNy0uNzA3bC0xLjE4MSAxLjE4LS4zOTItLjM5MWEuNS41IDAgMSAwLS43MDYuNzA4bC43NDYuNzQzYS40OTcuNDk3IDAgMCAwIC43MDYtLjAwMXpNNC41MjcgNy40NTJsMi41NTctMS41ODVBMSAxIDAgMCAwIDcuMDkgNC4xN0w0LjUzMyAyLjU2QTEgMSAwIDAgMCAzIDMuNDA2djMuMTk2YTEuMDAxIDEuMDAxIDAgMCAwIDEuNTI3Ljg1em0yLjAzLTIuNDM2TDQgNi42MDJWMy40MDZsMi41NTcgMS42MXpNMjQgMTIuNWMwIDEuOTMtMS41NyAzLjUtMy41IDMuNWEzLjUwMyAzLjUwMyAwIDAgMS0zLjQ2LTNoLTIuMDhhMy41MDMgMy41MDMgMCAwIDEtMy40NiAzIDMuNTAyIDMuNTAyIDAgMCAxLTMuNDYtM2gtLjU1OGMtLjk3MiAwLTEuODUtLjM5OS0yLjQ4Mi0xLjA0MlYxN2MwIDEuNjU0IDEuMzQ2IDMgMyAzaC4wNGMuMjQ0LTEuNjkzIDEuNy0zIDMuNDYtMyAxLjkzIDAgMy41IDEuNTcgMy41IDMuNVMxMy40MyAyNCAxMS41IDI0YTMuNTAyIDMuNTAyIDAgMCAxLTMuNDYtM0g4Yy0yLjIwNiAwLTQtMS43OTQtNC00VjkuODk5QTUuMDA4IDUuMDA4IDAgMCAxIDAgNWMwLTIuNzU3IDIuMjQzLTUgNS01czUgMi4yNDMgNSA1YTUuMDA1IDUuMDA1IDAgMCAxLTQuOTUyIDQuOTk4QTIuNDgyIDIuNDgyIDAgMCAwIDcuNDgyIDEyaC41NThjLjI0NC0xLjY5MyAxLjctMyAzLjQ2LTNhMy41MDIgMy41MDIgMCAwIDEgMy40NiAzaDIuMDhhMy41MDMgMy41MDMgMCAwIDEgMy40Ni0zYzEuOTMgMCAzLjUgMS41NyAzLjUgMy41em0tMTUgOGMwIDEuMzc4IDEuMTIyIDIuNSAyLjUgMi41czIuNS0xLjEyMiAyLjUtMi41LTEuMTIyLTIuNS0yLjUtMi41UzkgMTkuMTIyIDkgMjAuNXpNNSA5YzIuMjA2IDAgNC0xLjc5NCA0LTRTNy4yMDYgMSA1IDEgMSAyLjc5NCAxIDVzMS43OTQgNCA0IDR6bTkgMy41YzAtMS4zNzgtMS4xMjItMi41LTIuNS0yLjVTOSAxMS4xMjIgOSAxMi41czEuMTIyIDIuNSAyLjUgMi41IDIuNS0xLjEyMiAyLjUtMi41em05IDBjMC0xLjM3OC0xLjEyMi0yLjUtMi41LTIuNVMxOCAxMS4xMjIgMTggMTIuNXMxLjEyMiAyLjUgMi41IDIuNSAyLjUtMS4xMjIgMi41LTIuNXptLTEzIDhhLjUuNSAwIDEgMCAxIDAgLjUuNSAwIDAgMC0xIDB6bTIgMGEuNS41IDAgMSAwIDEgMCAuNS41IDAgMCAwLTEgMHptMTIgMGMwIDEuOTMtMS41NyAzLjUtMy41IDMuNWEzLjUwMyAzLjUwMyAwIDAgMS0zLjQ2LTMuMDAyYy0uMDA3LjAwMS0uMDEzLjAwNS0uMDIxLjAwNWwtLjUwNi4wMTdoLS4wMTdhLjUuNSAwIDAgMS0uMDE2LS45OTlsLjUwNi0uMDE3Yy4wMTgtLjAwMi4wMzUuMDA2LjA1Mi4wMDdBMy41MDMgMy41MDMgMCAwIDEgMjAuNSAxN2MxLjkzIDAgMy41IDEuNTcgMy41IDMuNXptLTEgMGMwLTEuMzc4LTEuMTIyLTIuNS0yLjUtMi41UzE4IDE5LjEyMiAxOCAyMC41czEuMTIyIDIuNSAyLjUgMi41IDIuNS0xLjEyMiAyLjUtMi41eiIvPjwvc3ZnPg==;labelPosition=center;verticalLabelPosition=bottom;align=center;verticalAlign=top;" vertex="1" parent="sOep82PyB1NGChh_XDzF-1">
                    <mxGeometry x="469" y="550" width="50" height="40" as="geometry"/>
                </mxCell>
                <mxCell id="sOep82PyB1NGChh_XDzF-27" style="edgeStyle=none;html=1;fontStyle=0" edge="1" parent="sOep82PyB1NGChh_XDzF-1" source="sOep82PyB1NGChh_XDzF-29" target="sOep82PyB1NGChh_XDzF-22">
                    <mxGeometry relative="1" as="geometry"/>
                </mxCell>
                <mxCell id="sOep82PyB1NGChh_XDzF-28" value="Trigger CI/CD Workflows" style="edgeStyle=none;html=1;labelPosition=center;verticalLabelPosition=top;align=center;verticalAlign=bottom;fontStyle=0" edge="1" parent="sOep82PyB1NGChh_XDzF-1" source="sOep82PyB1NGChh_XDzF-29" target="sOep82PyB1NGChh_XDzF-26">
                    <mxGeometry relative="1" as="geometry"/>
                </mxCell>
                <mxCell id="sOep82PyB1NGChh_XDzF-29" value="GitHub Repository" style="shape=image;editableCssRules=.*;image=data:image/svg+xml,PHN2ZyB2aWV3Qm94PSIwIDAgMjQgMjQiIHhtbG5zPSJodHRwOi8vd3d3LnczLm9yZy8yMDAwL3N2ZyI+PHN0eWxlPip7ZmlsbDojRjA1MDMyfTwvc3R5bGU+PHBhdGggZD0iTTIzLjU0NiAxMC45M0wxMy4wNjcuNDUyYy0uNjA0LS42MDMtMS41ODItLjYwMy0yLjE4OCAwTDguNzA4IDIuNjI3bDIuNzYgMi43NmMuNjQ1LS4yMTUgMS4zNzktLjA3IDEuODg5LjQ0MS41MTYuNTE1LjY1OCAxLjI1OC40MzggMS45bDIuNjU4IDIuNjZjLjY0NS0uMjIzIDEuMzg3LS4wNzggMS45LjQzNS43MjEuNzIuNzIxIDEuODg0IDAgMi42MDQtLjcxOS43MTktMS44ODEuNzE5LTIuNiAwLS41MzktLjU0MS0uNjc0LTEuMzM3LS40MDQtMS45OTZMMTIuODYgOC45NTV2Ni41MjVjLjE3Ni4wODYuMzQyLjIwMy40ODguMzQ4LjcxMy43MjEuNzEzIDEuODgzIDAgMi42LS43MTkuNzIxLTEuODg5LjcyMS0yLjYwOSAwLS43MTktLjcxOS0uNzE5LTEuODc5IDAtMi41OTguMTgyLS4xOC4zODctLjMxNi42MDUtLjQwNlY4LjgzNWMtLjIxNy0uMDkxLS40MjQtLjIyMi0uNi0uNDAxLS41NDUtLjU0NS0uNjc2LTEuMzQyLS4zOTYtMi4wMDlMNy42MzYgMy43LjQ1IDEwLjg4MWMtLjYuNjA1LS42IDEuNTg0IDAgMi4xODlsMTAuNDggMTAuNDc3Yy42MDQuNjA0IDEuNTgyLjYwNCAyLjE4NiAwbDEwLjQzLTEwLjQzYy42MDUtLjYwMy42MDUtMS41ODIgMC0yLjE4NyIvPjwvc3ZnPg==;labelPosition=center;verticalLabelPosition=bottom;align=center;verticalAlign=top;" vertex="1" parent="sOep82PyB1NGChh_XDzF-1">
                    <mxGeometry x="276" y="552" width="50" height="40" as="geometry"/>
                </mxCell>
                <mxCell id="sOep82PyB1NGChh_XDzF-30" style="edgeStyle=none;html=1;exitX=0.5;exitY=1;exitDx=0;exitDy=0;entryX=0.5;entryY=0;entryDx=0;entryDy=0;entryPerimeter=0;fontStyle=0" edge="1" parent="sOep82PyB1NGChh_XDzF-1" source="sOep82PyB1NGChh_XDzF-26" target="sOep82PyB1NGChh_XDzF-24">
                    <mxGeometry relative="1" as="geometry"/>
                </mxCell>
            </root>
        </mxGraphModel>
    </diagram>
    <diagram name="tf-aws-setup-maturity-level-0-solution-github-actions" id="mwSdYNyM5PpC_mEO38Fe">
        <mxGraphModel grid="0" page="0" gridSize="10" guides="1" tooltips="1" connect="1" arrows="1" fold="1" pageScale="1" pageWidth="1100" pageHeight="850" background="#ffffff" math="0" shadow="0">
            <root>
                <mxCell id="I7a3bJsOC2QIPho3Vu-L-0"/>
                <mxCell id="I7a3bJsOC2QIPho3Vu-L-1" parent="I7a3bJsOC2QIPho3Vu-L-0"/>
                <mxCell id="I7a3bJsOC2QIPho3Vu-L-2" value="&lt;span&gt;&amp;nbsp; &amp;nbsp; &amp;nbsp; GitHub&lt;/span&gt;" style="fillColor=none;strokeColor=#5A6C86;dashed=1;verticalAlign=top;fontStyle=0;fontColor=#5A6C86;whiteSpace=wrap;html=1;align=left;" parent="I7a3bJsOC2QIPho3Vu-L-1" vertex="1">
                    <mxGeometry x="225" y="471" width="432" height="317" as="geometry"/>
                </mxCell>
                <mxCell id="I7a3bJsOC2QIPho3Vu-L-3" value="AWS Account" style="points=[[0,0],[0.25,0],[0.5,0],[0.75,0],[1,0],[1,0.25],[1,0.5],[1,0.75],[1,1],[0.75,1],[0.5,1],[0.25,1],[0,1],[0,0.75],[0,0.5],[0,0.25]];outlineConnect=0;gradientColor=none;html=1;whiteSpace=wrap;fontSize=12;fontStyle=0;container=1;pointerEvents=0;collapsible=0;recursiveResize=0;shape=mxgraph.aws4.group;grIcon=mxgraph.aws4.group_account;strokeColor=#CD2264;fillColor=none;verticalAlign=top;align=left;spacingLeft=30;fontColor=#CD2264;dashed=0;" parent="I7a3bJsOC2QIPho3Vu-L-1" vertex="1">
                    <mxGeometry x="767" y="407" width="763" height="528" as="geometry"/>
                </mxCell>
                <mxCell id="I7a3bJsOC2QIPho3Vu-L-4" value="eu-north-1" style="points=[[0,0],[0.25,0],[0.5,0],[0.75,0],[1,0],[1,0.25],[1,0.5],[1,0.75],[1,1],[0.75,1],[0.5,1],[0.25,1],[0,1],[0,0.75],[0,0.5],[0,0.25]];outlineConnect=0;gradientColor=none;html=1;whiteSpace=wrap;fontSize=12;fontStyle=0;container=1;pointerEvents=0;collapsible=0;recursiveResize=0;shape=mxgraph.aws4.group;grIcon=mxgraph.aws4.group_region;strokeColor=#00A4A6;fillColor=none;verticalAlign=top;align=left;spacingLeft=30;fontColor=#147EBA;dashed=1;" parent="I7a3bJsOC2QIPho3Vu-L-3" vertex="1">
                    <mxGeometry x="30" y="166" width="640" height="305" as="geometry"/>
                </mxCell>
                <mxCell id="I7a3bJsOC2QIPho3Vu-L-5" value="S3 Backend" style="fillColor=none;strokeColor=#5A6C86;dashed=1;verticalAlign=top;fontStyle=0;fontColor=#5A6C86;whiteSpace=wrap;html=1;" parent="I7a3bJsOC2QIPho3Vu-L-4" vertex="1">
                    <mxGeometry x="29" y="46" width="335" height="192" as="geometry"/>
                </mxCell>
                <mxCell id="I7a3bJsOC2QIPho3Vu-L-6" style="edgeStyle=none;html=1;fontStyle=0" parent="I7a3bJsOC2QIPho3Vu-L-4" source="I7a3bJsOC2QIPho3Vu-L-7" target="I7a3bJsOC2QIPho3Vu-L-8" edge="1">
                    <mxGeometry relative="1" as="geometry"/>
                </mxCell>
                <mxCell id="I7a3bJsOC2QIPho3Vu-L-7" value="&lt;div&gt;&lt;span style=&quot;color: rgb(63, 63, 63); font-family: Helvetica; font-size: 12px; font-style: normal; font-variant-ligatures: normal; font-variant-caps: normal; font-weight: 400; letter-spacing: normal; orphans: 2; text-align: center; text-indent: 0px; text-transform: none; widows: 2; word-spacing: 0px; -webkit-text-stroke-width: 0px; white-space: nowrap; background-color: rgb(251, 251, 251); text-decoration-thickness: initial; text-decoration-style: initial; text-decoration-color: initial; float: none; display: inline !important;&quot;&gt;S3 Bucket&lt;/span&gt;&lt;/div&gt;&lt;span style=&quot;color: rgb(63, 63, 63); font-family: Helvetica; font-size: 12px; font-style: normal; font-variant-ligatures: normal; font-variant-caps: normal; font-weight: 400; letter-spacing: normal; orphans: 2; text-align: center; text-indent: 0px; text-transform: none; widows: 2; word-spacing: 0px; -webkit-text-stroke-width: 0px; white-space: nowrap; background-color: rgb(251, 251, 251); text-decoration-thickness: initial; text-decoration-style: initial; text-decoration-color: initial; float: none; display: inline !important;&quot;&gt;tf-remote-backends-ehb&lt;/span&gt;" style="sketch=0;outlineConnect=0;fontColor=#232F3E;gradientColor=none;fillColor=#7AA116;strokeColor=none;dashed=0;verticalLabelPosition=bottom;verticalAlign=top;align=center;html=1;fontSize=12;fontStyle=0;aspect=fixed;pointerEvents=1;shape=mxgraph.aws4.bucket;" parent="I7a3bJsOC2QIPho3Vu-L-4" vertex="1">
                    <mxGeometry x="91.73" y="66" width="36.54" height="38" as="geometry"/>
                </mxCell>
                <mxCell id="I7a3bJsOC2QIPho3Vu-L-8" value="terraform.tfstate" style="sketch=0;outlineConnect=0;fontColor=#232F3E;gradientColor=none;fillColor=#232F3D;strokeColor=none;dashed=0;verticalLabelPosition=bottom;verticalAlign=top;align=center;html=1;fontSize=12;fontStyle=0;aspect=fixed;pointerEvents=1;shape=mxgraph.aws4.document;" parent="I7a3bJsOC2QIPho3Vu-L-4" vertex="1">
                    <mxGeometry x="95.01999999999998" y="168" width="29.96" height="41" as="geometry"/>
                </mxCell>
                <mxCell id="I7a3bJsOC2QIPho3Vu-L-9" value="Encryption" style="sketch=0;outlineConnect=0;gradientColor=none;fillColor=#DD344C;strokeColor=none;dashed=0;verticalLabelPosition=bottom;verticalAlign=top;align=center;aspect=fixed;pointerEvents=1;shape=mxgraph.aws4.data_encryption_key;html=1;" parent="I7a3bJsOC2QIPho3Vu-L-4" vertex="1">
                    <mxGeometry x="317" y="49" width="26.23" height="33" as="geometry"/>
                </mxCell>
                <mxCell id="I7a3bJsOC2QIPho3Vu-L-10" value="Versioning" style="image;aspect=fixed;points=[];align=center;image=img/lib/azure2/general/Versions.svg;html=1;" parent="I7a3bJsOC2QIPho3Vu-L-4" vertex="1">
                    <mxGeometry x="314.16000000000025" y="113.5" width="27.9" height="27" as="geometry"/>
                </mxCell>
                <mxCell id="I7a3bJsOC2QIPho3Vu-L-11" value="State Lock" style="html=1;verticalLabelPosition=bottom;align=center;labelBackgroundColor=#ffffff;verticalAlign=top;strokeWidth=2;strokeColor=#0080F0;shadow=0;dashed=0;shape=mxgraph.ios7.icons.locked;" parent="I7a3bJsOC2QIPho3Vu-L-4" vertex="1">
                    <mxGeometry x="316" y="171" width="24" height="30" as="geometry"/>
                </mxCell>
                <mxCell id="0" value="&lt;div&gt;&lt;span style=&quot;color: rgb(63, 63, 63); font-family: Helvetica; font-size: 12px; font-style: normal; font-variant-ligatures: normal; font-variant-caps: normal; font-weight: 400; letter-spacing: normal; orphans: 2; text-align: center; text-indent: 0px; text-transform: none; widows: 2; word-spacing: 0px; -webkit-text-stroke-width: 0px; white-space: nowrap; background-color: rgb(251, 251, 251); text-decoration-thickness: initial; text-decoration-style: initial; text-decoration-color: initial; float: none; display: inline !important;&quot;&gt;S3 Bucket&lt;/span&gt;&lt;/div&gt;&lt;div&gt;&lt;span style=&quot;orphans: 2; text-align: center; text-indent: 0px; widows: 2; background-color: rgb(251, 251, 251); text-decoration-thickness: initial; text-decoration-style: initial; text-decoration-color: initial; float: none; display: inline !important; color: rgb(63, 63, 63);&quot;&gt;mlops-course-ehb-data-dev&lt;/span&gt;&lt;/div&gt;" style="sketch=0;outlineConnect=0;fontColor=#232F3E;gradientColor=none;fillColor=#7AA116;strokeColor=none;dashed=0;verticalLabelPosition=bottom;verticalAlign=top;align=center;html=1;fontSize=12;fontStyle=0;aspect=fixed;pointerEvents=1;shape=mxgraph.aws4.bucket;" parent="I7a3bJsOC2QIPho3Vu-L-4" vertex="1">
                    <mxGeometry x="480" y="66" width="36.54" height="38" as="geometry"/>
                </mxCell>
                <mxCell id="I7a3bJsOC2QIPho3Vu-L-12" style="edgeStyle=none;html=1;fontStyle=0" parent="I7a3bJsOC2QIPho3Vu-L-3" source="I7a3bJsOC2QIPho3Vu-L-13" target="I7a3bJsOC2QIPho3Vu-L-15" edge="1">
                    <mxGeometry relative="1" as="geometry"/>
                </mxCell>
                <mxCell id="I7a3bJsOC2QIPho3Vu-L-13" value="IAM User&lt;div&gt;Terraform User&lt;/div&gt;" style="sketch=0;outlineConnect=0;fontColor=#232F3E;gradientColor=none;fillColor=#DD344C;strokeColor=none;dashed=0;verticalLabelPosition=bottom;verticalAlign=top;align=center;html=1;fontSize=12;fontStyle=0;aspect=fixed;pointerEvents=1;shape=mxgraph.aws4.role;" parent="I7a3bJsOC2QIPho3Vu-L-3" vertex="1">
                    <mxGeometry x="93" y="64" width="33.68" height="19" as="geometry"/>
                </mxCell>
                <mxCell id="I7a3bJsOC2QIPho3Vu-L-14" style="edgeStyle=none;html=1;fontStyle=0" parent="I7a3bJsOC2QIPho3Vu-L-3" source="I7a3bJsOC2QIPho3Vu-L-15" target="I7a3bJsOC2QIPho3Vu-L-5" edge="1">
                    <mxGeometry relative="1" as="geometry"/>
                </mxCell>
                <mxCell id="I7a3bJsOC2QIPho3Vu-L-15" value="&lt;div&gt;IAM Role&lt;/div&gt;Administrative Access&amp;nbsp;" style="sketch=0;outlineConnect=0;fontColor=#232F3E;gradientColor=none;fillColor=#DD344C;strokeColor=none;dashed=0;verticalLabelPosition=bottom;verticalAlign=top;align=center;html=1;fontSize=12;fontStyle=0;aspect=fixed;pointerEvents=1;shape=mxgraph.aws4.long_term_security_credential;" parent="I7a3bJsOC2QIPho3Vu-L-3" vertex="1">
                    <mxGeometry x="212" y="58" width="35.04" height="31" as="geometry"/>
                </mxCell>
                <mxCell id="axX2pNqQfqSjAvKcueDQ-0" style="edgeStyle=none;html=1;entryX=0;entryY=0.5;entryDx=0;entryDy=0;fontStyle=0" parent="I7a3bJsOC2QIPho3Vu-L-1" source="I7a3bJsOC2QIPho3Vu-L-17" target="I7a3bJsOC2QIPho3Vu-L-3" edge="1">
                    <mxGeometry relative="1" as="geometry"/>
                </mxCell>
                <mxCell id="I7a3bJsOC2QIPho3Vu-L-17" value="Terraform CLI" style="shape=image;verticalLabelPosition=bottom;verticalAlign=top;imageAspect=0;aspect=fixed;image=data:image/svg+xml,PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHZpZXdCb3g9IjAgNy41IDUwIDU3IiBoZWlnaHQ9IjU3IiB3aWR0aD0iNTAiIGlkPSJMb2dvcyI+PGRlZnM+PHN0eWxlPi5jbHMtMXtmaWxsOiM3YjQyYmM7ZmlsbC1ydWxlOmV2ZW5vZGQ7c3Ryb2tlLXdpZHRoOjBweDt9PC9zdHlsZT48L2RlZnM+PHBhdGggZD0iTTE3LjMsMTcuNWwxNS41LDl2MThsLTE1LjUtOXYtMThaIiBjbGFzcz0iY2xzLTEiLz48cGF0aCBkPSJNMzQuNSwyNi41djE4bDE1LjUtOXYtMThsLTE1LjUsOVoiIGNsYXNzPSJjbHMtMSIvPjxwYXRoIGQ9Ik0wLDcuNXYxOGwxNS41LDl2LTE4TDAsNy41WiIgY2xhc3M9ImNscy0xIi8+PHBhdGggZD0iTTE3LjMsNTUuNWwxNS41LDl2LTE4bC0xNS41LTl2MThaIiBjbGFzcz0iY2xzLTEiLz48L3N2Zz4=;" parent="I7a3bJsOC2QIPho3Vu-L-1" vertex="1">
                    <mxGeometry x="574" y="649" width="42.11" height="48" as="geometry"/>
                </mxCell>
                <mxCell id="2RC_NORF-FVhNrAbsMOE-4" style="edgeStyle=none;html=1;entryX=0;entryY=0.5;entryDx=0;entryDy=0;labelPosition=center;verticalLabelPosition=top;align=center;verticalAlign=bottom;fontStyle=0" parent="I7a3bJsOC2QIPho3Vu-L-1" target="I7a3bJsOC2QIPho3Vu-L-2" edge="1">
                    <mxGeometry relative="1" as="geometry">
                        <mxPoint x="111" y="628" as="sourcePoint"/>
                    </mxGeometry>
                </mxCell>
                <mxCell id="2RC_NORF-FVhNrAbsMOE-5" value="Commit &amp;amp; Push" style="edgeLabel;html=1;align=center;verticalAlign=bottom;resizable=0;points=[];labelPosition=center;verticalLabelPosition=top;" parent="2RC_NORF-FVhNrAbsMOE-4" vertex="1" connectable="0">
                    <mxGeometry x="0.0711" relative="1" as="geometry">
                        <mxPoint as="offset"/>
                    </mxGeometry>
                </mxCell>
                <mxCell id="I7a3bJsOC2QIPho3Vu-L-18" value="Developer X" style="sketch=0;outlineConnect=0;fontColor=#232F3E;gradientColor=none;fillColor=#232F3D;strokeColor=none;dashed=0;verticalLabelPosition=bottom;verticalAlign=top;align=center;html=1;fontSize=12;fontStyle=0;aspect=fixed;pointerEvents=1;shape=mxgraph.aws4.user;" parent="I7a3bJsOC2QIPho3Vu-L-1" vertex="1">
                    <mxGeometry x="74" y="608" width="39" height="39" as="geometry"/>
                </mxCell>
                <mxCell id="I7a3bJsOC2QIPho3Vu-L-20" value="Terraform&amp;nbsp;&lt;span style=&quot;background-color: transparent;&quot;&gt;Files&lt;/span&gt;" style="sketch=0;outlineConnect=0;fontColor=#232F3E;gradientColor=none;fillColor=#232F3D;strokeColor=none;dashed=0;verticalLabelPosition=bottom;verticalAlign=top;align=center;html=1;fontSize=12;fontStyle=0;aspect=fixed;pointerEvents=1;shape=mxgraph.aws4.documents3;" parent="I7a3bJsOC2QIPho3Vu-L-1" vertex="1">
                    <mxGeometry x="284" y="663" width="30.69" height="42" as="geometry"/>
                </mxCell>
                <mxCell id="2RC_NORF-FVhNrAbsMOE-0" style="edgeStyle=none;html=1;exitX=1;exitY=0.5;exitDx=0;exitDy=0;exitPerimeter=0;entryX=0;entryY=0.5;entryDx=0;entryDy=0;fontStyle=0" parent="I7a3bJsOC2QIPho3Vu-L-1" source="I7a3bJsOC2QIPho3Vu-L-21" target="I7a3bJsOC2QIPho3Vu-L-17" edge="1">
                    <mxGeometry relative="1" as="geometry"/>
                </mxCell>
                <mxCell id="I7a3bJsOC2QIPho3Vu-L-21" value="AWS CLI&amp;nbsp;&lt;span style=&quot;background-color: transparent;&quot;&gt;&amp;amp;&amp;nbsp;&lt;/span&gt;&lt;div&gt;&lt;span style=&quot;background-color: transparent;&quot;&gt;Access Key&lt;/span&gt;&lt;/div&gt;" style="sketch=0;points=[[0,0,0],[0.25,0,0],[0.5,0,0],[0.75,0,0],[1,0,0],[0,1,0],[0.25,1,0],[0.5,1,0],[0.75,1,0],[1,1,0],[0,0.25,0],[0,0.5,0],[0,0.75,0],[1,0.25,0],[1,0.5,0],[1,0.75,0]];points=[[0,0,0],[0.25,0,0],[0.5,0,0],[0.75,0,0],[1,0,0],[0,1,0],[0.25,1,0],[0.5,1,0],[0.75,1,0],[1,1,0],[0,0.25,0],[0,0.5,0],[0,0.75,0],[1,0.25,0],[1,0.5,0],[1,0.75,0]];outlineConnect=0;fontColor=#232F3E;fillColor=#E7157B;strokeColor=#ffffff;dashed=0;verticalLabelPosition=bottom;verticalAlign=top;align=center;html=1;fontSize=12;fontStyle=0;aspect=fixed;shape=mxgraph.aws4.resourceIcon;resIcon=mxgraph.aws4.command_line_interface;" parent="I7a3bJsOC2QIPho3Vu-L-1" vertex="1">
                    <mxGeometry x="477" y="656" width="35" height="35" as="geometry"/>
                </mxCell>
                <mxCell id="6hvZE7LONXoAUK2N37oM-7" style="shape=image;editableCssRules=.*;image=data:image/svg+xml,PHN2ZyB2aWV3Qm94PSIwIDAgMjQgMjQiIHhtbG5zPSJodHRwOi8vd3d3LnczLm9yZy8yMDAwL3N2ZyI+PHN0eWxlPip7ZmlsbDojMTgxNzE3fTwvc3R5bGU+PHBhdGggZD0iTTEyIC4yOTdjLTYuNjMgMC0xMiA1LjM3My0xMiAxMiAwIDUuMzAzIDMuNDM4IDkuOCA4LjIwNSAxMS4zODUuNi4xMTMuODItLjI1OC44Mi0uNTc3IDAtLjI4NS0uMDEtMS4wNC0uMDE1LTIuMDQtMy4zMzguNzI0LTQuMDQyLTEuNjEtNC4wNDItMS42MUM0LjQyMiAxOC4wNyAzLjYzMyAxNy43IDMuNjMzIDE3LjdjLTEuMDg3LS43NDQuMDg0LS43MjkuMDg0LS43MjkgMS4yMDUuMDg0IDEuODM4IDEuMjM2IDEuODM4IDEuMjM2IDEuMDcgMS44MzUgMi44MDkgMS4zMDUgMy40OTUuOTk4LjEwOC0uNzc2LjQxNy0xLjMwNS43Ni0xLjYwNS0yLjY2NS0uMy01LjQ2Ni0xLjMzMi01LjQ2Ni01LjkzIDAtMS4zMS40NjUtMi4zOCAxLjIzNS0zLjIyLS4xMzUtLjMwMy0uNTQtMS41MjMuMTA1LTMuMTc2IDAgMCAxLjAwNS0uMzIyIDMuMyAxLjIzLjk2LS4yNjcgMS45OC0uMzk5IDMtLjQwNSAxLjAyLjAwNiAyLjA0LjEzOCAzIC40MDUgMi4yOC0xLjU1MiAzLjI4NS0xLjIzIDMuMjg1LTEuMjMuNjQ1IDEuNjUzLjI0IDIuODczLjEyIDMuMTc2Ljc2NS44NCAxLjIzIDEuOTEgMS4yMyAzLjIyIDAgNC42MS0yLjgwNSA1LjYyNS01LjQ3NSA1LjkyLjQyLjM2LjgxIDEuMDk2LjgxIDIuMjIgMCAxLjYwNi0uMDE1IDIuODk2LS4wMTUgMy4yODYgMCAuMzE1LjIxLjY5LjgyNS41N0MyMC41NjUgMjIuMDkyIDI0IDE3LjU5MiAyNCAxMi4yOTdjMC02LjYyNy01LjM3My0xMi0xMi0xMiIvPjwvc3ZnPg==;" parent="I7a3bJsOC2QIPho3Vu-L-1" vertex="1">
                    <mxGeometry x="205" y="475" width="62" height="15" as="geometry"/>
                </mxCell>
                <mxCell id="6hvZE7LONXoAUK2N37oM-8" value="GitHub Actions" style="shape=image;editableCssRules=.*;image=data:image/svg+xml,PHN2ZyB2aWV3Qm94PSIwIDAgMjQgMjQiIHhtbG5zPSJodHRwOi8vd3d3LnczLm9yZy8yMDAwL3N2ZyI+PHN0eWxlPip7ZmlsbDojMjA4OEZGfTwvc3R5bGU+PHBhdGggZD0iTTEwLjk4NCAxMy44MzZhLjUuNSAwIDAgMS0uMzUzLS4xNDZsLS43NDUtLjc0M2EuNS41IDAgMSAxIC43MDYtLjcwOGwuMzkyLjM5MSAxLjE4MS0xLjE4YS41LjUgMCAwIDEgLjcwOC43MDdsLTEuNTM1IDEuNTMzYS41MDQuNTA0IDAgMCAxLS4zNTQuMTQ2em05LjM1My0uMTQ3bDEuNTM0LTEuNTMyYS41LjUgMCAwIDAtLjcwNy0uNzA3bC0xLjE4MSAxLjE4LS4zOTItLjM5MWEuNS41IDAgMSAwLS43MDYuNzA4bC43NDYuNzQzYS40OTcuNDk3IDAgMCAwIC43MDYtLjAwMXpNNC41MjcgNy40NTJsMi41NTctMS41ODVBMSAxIDAgMCAwIDcuMDkgNC4xN0w0LjUzMyAyLjU2QTEgMSAwIDAgMCAzIDMuNDA2djMuMTk2YTEuMDAxIDEuMDAxIDAgMCAwIDEuNTI3Ljg1em0yLjAzLTIuNDM2TDQgNi42MDJWMy40MDZsMi41NTcgMS42MXpNMjQgMTIuNWMwIDEuOTMtMS41NyAzLjUtMy41IDMuNWEzLjUwMyAzLjUwMyAwIDAgMS0zLjQ2LTNoLTIuMDhhMy41MDMgMy41MDMgMCAwIDEtMy40NiAzIDMuNTAyIDMuNTAyIDAgMCAxLTMuNDYtM2gtLjU1OGMtLjk3MiAwLTEuODUtLjM5OS0yLjQ4Mi0xLjA0MlYxN2MwIDEuNjU0IDEuMzQ2IDMgMyAzaC4wNGMuMjQ0LTEuNjkzIDEuNy0zIDMuNDYtMyAxLjkzIDAgMy41IDEuNTcgMy41IDMuNVMxMy40MyAyNCAxMS41IDI0YTMuNTAyIDMuNTAyIDAgMCAxLTMuNDYtM0g4Yy0yLjIwNiAwLTQtMS43OTQtNC00VjkuODk5QTUuMDA4IDUuMDA4IDAgMCAxIDAgNWMwLTIuNzU3IDIuMjQzLTUgNS01czUgMi4yNDMgNSA1YTUuMDA1IDUuMDA1IDAgMCAxLTQuOTUyIDQuOTk4QTIuNDgyIDIuNDgyIDAgMCAwIDcuNDgyIDEyaC41NThjLjI0NC0xLjY5MyAxLjctMyAzLjQ2LTNhMy41MDIgMy41MDIgMCAwIDEgMy40NiAzaDIuMDhhMy41MDMgMy41MDMgMCAwIDEgMy40Ni0zYzEuOTMgMCAzLjUgMS41NyAzLjUgMy41em0tMTUgOGMwIDEuMzc4IDEuMTIyIDIuNSAyLjUgMi41czIuNS0xLjEyMiAyLjUtMi41LTEuMTIyLTIuNS0yLjUtMi41UzkgMTkuMTIyIDkgMjAuNXpNNSA5YzIuMjA2IDAgNC0xLjc5NCA0LTRTNy4yMDYgMSA1IDEgMSAyLjc5NCAxIDVzMS43OTQgNCA0IDR6bTkgMy41YzAtMS4zNzgtMS4xMjItMi41LTIuNS0yLjVTOSAxMS4xMjIgOSAxMi41czEuMTIyIDIuNSAyLjUgMi41IDIuNS0xLjEyMiAyLjUtMi41em05IDBjMC0xLjM3OC0xLjEyMi0yLjUtMi41LTIuNVMxOCAxMS4xMjIgMTggMTIuNXMxLjEyMiAyLjUgMi41IDIuNSAyLjUtMS4xMjIgMi41LTIuNXptLTEzIDhhLjUuNSAwIDEgMCAxIDAgLjUuNSAwIDAgMC0xIDB6bTIgMGEuNS41IDAgMSAwIDEgMCAuNS41IDAgMCAwLTEgMHptMTIgMGMwIDEuOTMtMS41NyAzLjUtMy41IDMuNWEzLjUwMyAzLjUwMyAwIDAgMS0zLjQ2LTMuMDAyYy0uMDA3LjAwMS0uMDEzLjAwNS0uMDIxLjAwNWwtLjUwNi4wMTdoLS4wMTdhLjUuNSAwIDAgMS0uMDE2LS45OTlsLjUwNi0uMDE3Yy4wMTgtLjAwMi4wMzUuMDA2LjA1Mi4wMDdBMy41MDMgMy41MDMgMCAwIDEgMjAuNSAxN2MxLjkzIDAgMy41IDEuNTcgMy41IDMuNXptLTEgMGMwLTEuMzc4LTEuMTIyLTIuNS0yLjUtMi41UzE4IDE5LjEyMiAxOCAyMC41czEuMTIyIDIuNSAyLjUgMi41IDIuNS0xLjEyMiAyLjUtMi41eiIvPjwvc3ZnPg==;labelPosition=center;verticalLabelPosition=bottom;align=center;verticalAlign=top;" parent="I7a3bJsOC2QIPho3Vu-L-1" vertex="1">
                    <mxGeometry x="469" y="550" width="50" height="40" as="geometry"/>
                </mxCell>
                <mxCell id="6hvZE7LONXoAUK2N37oM-11" style="edgeStyle=none;html=1;fontStyle=0" parent="I7a3bJsOC2QIPho3Vu-L-1" source="6hvZE7LONXoAUK2N37oM-10" target="I7a3bJsOC2QIPho3Vu-L-20" edge="1">
                    <mxGeometry relative="1" as="geometry"/>
                </mxCell>
                <mxCell id="6hvZE7LONXoAUK2N37oM-12" value="Trigger CI/CD Workflows" style="edgeStyle=none;html=1;labelPosition=center;verticalLabelPosition=top;align=center;verticalAlign=bottom;fontStyle=0" parent="I7a3bJsOC2QIPho3Vu-L-1" source="6hvZE7LONXoAUK2N37oM-10" target="6hvZE7LONXoAUK2N37oM-8" edge="1">
                    <mxGeometry relative="1" as="geometry"/>
                </mxCell>
                <mxCell id="6hvZE7LONXoAUK2N37oM-10" value="GitHub Repository" style="shape=image;editableCssRules=.*;image=data:image/svg+xml,PHN2ZyB2aWV3Qm94PSIwIDAgMjQgMjQiIHhtbG5zPSJodHRwOi8vd3d3LnczLm9yZy8yMDAwL3N2ZyI+PHN0eWxlPip7ZmlsbDojRjA1MDMyfTwvc3R5bGU+PHBhdGggZD0iTTIzLjU0NiAxMC45M0wxMy4wNjcuNDUyYy0uNjA0LS42MDMtMS41ODItLjYwMy0yLjE4OCAwTDguNzA4IDIuNjI3bDIuNzYgMi43NmMuNjQ1LS4yMTUgMS4zNzktLjA3IDEuODg5LjQ0MS41MTYuNTE1LjY1OCAxLjI1OC40MzggMS45bDIuNjU4IDIuNjZjLjY0NS0uMjIzIDEuMzg3LS4wNzggMS45LjQzNS43MjEuNzIuNzIxIDEuODg0IDAgMi42MDQtLjcxOS43MTktMS44ODEuNzE5LTIuNiAwLS41MzktLjU0MS0uNjc0LTEuMzM3LS40MDQtMS45OTZMMTIuODYgOC45NTV2Ni41MjVjLjE3Ni4wODYuMzQyLjIwMy40ODguMzQ4LjcxMy43MjEuNzEzIDEuODgzIDAgMi42LS43MTkuNzIxLTEuODg5LjcyMS0yLjYwOSAwLS43MTktLjcxOS0uNzE5LTEuODc5IDAtMi41OTguMTgyLS4xOC4zODctLjMxNi42MDUtLjQwNlY4LjgzNWMtLjIxNy0uMDkxLS40MjQtLjIyMi0uNi0uNDAxLS41NDUtLjU0NS0uNjc2LTEuMzQyLS4zOTYtMi4wMDlMNy42MzYgMy43LjQ1IDEwLjg4MWMtLjYuNjA1LS42IDEuNTg0IDAgMi4xODlsMTAuNDggMTAuNDc3Yy42MDQuNjA0IDEuNTgyLjYwNCAyLjE4NiAwbDEwLjQzLTEwLjQzYy42MDUtLjYwMy42MDUtMS41ODIgMC0yLjE4NyIvPjwvc3ZnPg==;labelPosition=center;verticalLabelPosition=bottom;align=center;verticalAlign=top;" parent="I7a3bJsOC2QIPho3Vu-L-1" vertex="1">
                    <mxGeometry x="276" y="552" width="50" height="40" as="geometry"/>
                </mxCell>
                <mxCell id="2RC_NORF-FVhNrAbsMOE-2" style="edgeStyle=none;html=1;exitX=0.5;exitY=1;exitDx=0;exitDy=0;entryX=0.5;entryY=0;entryDx=0;entryDy=0;entryPerimeter=0;fontStyle=0" parent="I7a3bJsOC2QIPho3Vu-L-1" source="6hvZE7LONXoAUK2N37oM-8" target="I7a3bJsOC2QIPho3Vu-L-21" edge="1">
                    <mxGeometry relative="1" as="geometry"/>
                </mxCell>
            </root>
        </mxGraphModel>
    </diagram>
    <diagram name="tf-aws-setup-maturity-level-0-solution-remote-backend" id="qeGhzs8fQwmjpmQWkRHa">
        <mxGraphModel dx="1626" dy="1094" grid="0" gridSize="10" guides="1" tooltips="1" connect="1" arrows="1" fold="1" page="0" pageScale="1" pageWidth="1100" pageHeight="850" background="#ffffff" math="0" shadow="0">
            <root>
                <mxCell id="_ASd7ttjQse1Z8Tchp8T-0"/>
                <mxCell id="_ASd7ttjQse1Z8Tchp8T-1" parent="_ASd7ttjQse1Z8Tchp8T-0"/>
                <mxCell id="_ASd7ttjQse1Z8Tchp8T-2" value="Local Development Environment" style="fillColor=none;strokeColor=#5A6C86;dashed=1;verticalAlign=top;fontStyle=0;fontColor=#5A6C86;whiteSpace=wrap;html=1;" vertex="1" parent="_ASd7ttjQse1Z8Tchp8T-1">
                    <mxGeometry x="202" y="423" width="430" height="193" as="geometry"/>
                </mxCell>
                <mxCell id="_ASd7ttjQse1Z8Tchp8T-3" value="AWS Account" style="points=[[0,0],[0.25,0],[0.5,0],[0.75,0],[1,0],[1,0.25],[1,0.5],[1,0.75],[1,1],[0.75,1],[0.5,1],[0.25,1],[0,1],[0,0.75],[0,0.5],[0,0.25]];outlineConnect=0;gradientColor=none;html=1;whiteSpace=wrap;fontSize=12;fontStyle=0;container=1;pointerEvents=0;collapsible=0;recursiveResize=0;shape=mxgraph.aws4.group;grIcon=mxgraph.aws4.group_account;strokeColor=#CD2264;fillColor=none;verticalAlign=top;align=left;spacingLeft=30;fontColor=#CD2264;dashed=0;" vertex="1" parent="_ASd7ttjQse1Z8Tchp8T-1">
                    <mxGeometry x="767" y="407" width="612" height="528" as="geometry"/>
                </mxCell>
                <mxCell id="_ASd7ttjQse1Z8Tchp8T-4" value="eu-north-1" style="points=[[0,0],[0.25,0],[0.5,0],[0.75,0],[1,0],[1,0.25],[1,0.5],[1,0.75],[1,1],[0.75,1],[0.5,1],[0.25,1],[0,1],[0,0.75],[0,0.5],[0,0.25]];outlineConnect=0;gradientColor=none;html=1;whiteSpace=wrap;fontSize=12;fontStyle=0;container=1;pointerEvents=0;collapsible=0;recursiveResize=0;shape=mxgraph.aws4.group;grIcon=mxgraph.aws4.group_region;strokeColor=#00A4A6;fillColor=none;verticalAlign=top;align=left;spacingLeft=30;fontColor=#147EBA;dashed=1;" vertex="1" parent="_ASd7ttjQse1Z8Tchp8T-3">
                    <mxGeometry x="30" y="166" width="475" height="305" as="geometry"/>
                </mxCell>
                <mxCell id="_ASd7ttjQse1Z8Tchp8T-8" value="S3 Backend" style="fillColor=none;strokeColor=#5A6C86;dashed=1;verticalAlign=top;fontStyle=0;fontColor=#5A6C86;whiteSpace=wrap;html=1;" vertex="1" parent="_ASd7ttjQse1Z8Tchp8T-4">
                    <mxGeometry x="29" y="46" width="335" height="192" as="geometry"/>
                </mxCell>
                <mxCell id="_ASd7ttjQse1Z8Tchp8T-5" style="edgeStyle=none;html=1;" edge="1" parent="_ASd7ttjQse1Z8Tchp8T-4" source="_ASd7ttjQse1Z8Tchp8T-6" target="_ASd7ttjQse1Z8Tchp8T-7">
                    <mxGeometry relative="1" as="geometry"/>
                </mxCell>
                <mxCell id="_ASd7ttjQse1Z8Tchp8T-6" value="&lt;div&gt;&lt;span style=&quot;color: rgb(63, 63, 63); font-family: Helvetica; font-size: 12px; font-style: normal; font-variant-ligatures: normal; font-variant-caps: normal; font-weight: 400; letter-spacing: normal; orphans: 2; text-align: center; text-indent: 0px; text-transform: none; widows: 2; word-spacing: 0px; -webkit-text-stroke-width: 0px; white-space: nowrap; background-color: rgb(251, 251, 251); text-decoration-thickness: initial; text-decoration-style: initial; text-decoration-color: initial; float: none; display: inline !important;&quot;&gt;S3 Bucket&lt;/span&gt;&lt;/div&gt;&lt;span style=&quot;color: rgb(63, 63, 63); font-family: Helvetica; font-size: 12px; font-style: normal; font-variant-ligatures: normal; font-variant-caps: normal; font-weight: 400; letter-spacing: normal; orphans: 2; text-align: center; text-indent: 0px; text-transform: none; widows: 2; word-spacing: 0px; -webkit-text-stroke-width: 0px; white-space: nowrap; background-color: rgb(251, 251, 251); text-decoration-thickness: initial; text-decoration-style: initial; text-decoration-color: initial; float: none; display: inline !important;&quot;&gt;tf-remote-backends-ehb&lt;/span&gt;" style="sketch=0;outlineConnect=0;fontColor=#232F3E;gradientColor=none;fillColor=#7AA116;strokeColor=none;dashed=0;verticalLabelPosition=bottom;verticalAlign=top;align=center;html=1;fontSize=12;fontStyle=0;aspect=fixed;pointerEvents=1;shape=mxgraph.aws4.bucket;" vertex="1" parent="_ASd7ttjQse1Z8Tchp8T-4">
                    <mxGeometry x="91.73" y="66" width="36.54" height="38" as="geometry"/>
                </mxCell>
                <mxCell id="_ASd7ttjQse1Z8Tchp8T-7" value="terraform.tfstate" style="sketch=0;outlineConnect=0;fontColor=#232F3E;gradientColor=none;fillColor=#232F3D;strokeColor=none;dashed=0;verticalLabelPosition=bottom;verticalAlign=top;align=center;html=1;fontSize=12;fontStyle=0;aspect=fixed;pointerEvents=1;shape=mxgraph.aws4.document;" vertex="1" parent="_ASd7ttjQse1Z8Tchp8T-4">
                    <mxGeometry x="95.01999999999998" y="168" width="29.96" height="41" as="geometry"/>
                </mxCell>
                <mxCell id="_ASd7ttjQse1Z8Tchp8T-9" value="Encryption" style="sketch=0;outlineConnect=0;gradientColor=none;fillColor=#DD344C;strokeColor=none;dashed=0;verticalLabelPosition=bottom;verticalAlign=top;align=center;aspect=fixed;pointerEvents=1;shape=mxgraph.aws4.data_encryption_key;html=1;" vertex="1" parent="_ASd7ttjQse1Z8Tchp8T-4">
                    <mxGeometry x="317" y="49" width="26.23" height="33" as="geometry"/>
                </mxCell>
                <mxCell id="_ASd7ttjQse1Z8Tchp8T-10" value="Versioning" style="image;aspect=fixed;points=[];align=center;image=img/lib/azure2/general/Versions.svg;html=1;" vertex="1" parent="_ASd7ttjQse1Z8Tchp8T-4">
                    <mxGeometry x="314.16000000000025" y="113.5" width="27.9" height="27" as="geometry"/>
                </mxCell>
                <mxCell id="_ASd7ttjQse1Z8Tchp8T-11" value="State Lock" style="html=1;verticalLabelPosition=bottom;align=center;labelBackgroundColor=#ffffff;verticalAlign=top;strokeWidth=2;strokeColor=#0080F0;shadow=0;dashed=0;shape=mxgraph.ios7.icons.locked;" vertex="1" parent="_ASd7ttjQse1Z8Tchp8T-4">
                    <mxGeometry x="316" y="171" width="24" height="30" as="geometry"/>
                </mxCell>
                <mxCell id="2i4daaO1fAzA4-PC_4SC-1" style="edgeStyle=none;html=1;" edge="1" parent="_ASd7ttjQse1Z8Tchp8T-3" source="rk6-1DMPQsgmVRxzv6lK-0" target="2i4daaO1fAzA4-PC_4SC-0">
                    <mxGeometry relative="1" as="geometry"/>
                </mxCell>
                <mxCell id="rk6-1DMPQsgmVRxzv6lK-0" value="IAM User&lt;div&gt;Terraform User&lt;/div&gt;" style="sketch=0;outlineConnect=0;fontColor=#232F3E;gradientColor=none;fillColor=#DD344C;strokeColor=none;dashed=0;verticalLabelPosition=bottom;verticalAlign=top;align=center;html=1;fontSize=12;fontStyle=0;aspect=fixed;pointerEvents=1;shape=mxgraph.aws4.role;" vertex="1" parent="_ASd7ttjQse1Z8Tchp8T-3">
                    <mxGeometry x="93" y="64" width="33.68" height="19" as="geometry"/>
                </mxCell>
                <mxCell id="2i4daaO1fAzA4-PC_4SC-2" style="edgeStyle=none;html=1;" edge="1" parent="_ASd7ttjQse1Z8Tchp8T-3" source="2i4daaO1fAzA4-PC_4SC-0" target="_ASd7ttjQse1Z8Tchp8T-8">
                    <mxGeometry relative="1" as="geometry"/>
                </mxCell>
                <mxCell id="2i4daaO1fAzA4-PC_4SC-0" value="&lt;div&gt;IAM Role&lt;/div&gt;Administrative Access&amp;nbsp;" style="sketch=0;outlineConnect=0;fontColor=#232F3E;gradientColor=none;fillColor=#DD344C;strokeColor=none;dashed=0;verticalLabelPosition=bottom;verticalAlign=top;align=center;html=1;fontSize=12;fontStyle=0;aspect=fixed;pointerEvents=1;shape=mxgraph.aws4.long_term_security_credential;" vertex="1" parent="_ASd7ttjQse1Z8Tchp8T-3">
                    <mxGeometry x="212" y="58" width="35.04" height="31" as="geometry"/>
                </mxCell>
                <mxCell id="_ASd7ttjQse1Z8Tchp8T-12" style="edgeStyle=none;html=1;entryX=0;entryY=0.5;entryDx=0;entryDy=0;" edge="1" parent="_ASd7ttjQse1Z8Tchp8T-1" source="_ASd7ttjQse1Z8Tchp8T-13" target="_ASd7ttjQse1Z8Tchp8T-3">
                    <mxGeometry relative="1" as="geometry"/>
                </mxCell>
                <mxCell id="_ASd7ttjQse1Z8Tchp8T-13" value="Terraform CLI" style="shape=image;verticalLabelPosition=bottom;verticalAlign=top;imageAspect=0;aspect=fixed;image=data:image/svg+xml,PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHZpZXdCb3g9IjAgNy41IDUwIDU3IiBoZWlnaHQ9IjU3IiB3aWR0aD0iNTAiIGlkPSJMb2dvcyI+PGRlZnM+PHN0eWxlPi5jbHMtMXtmaWxsOiM3YjQyYmM7ZmlsbC1ydWxlOmV2ZW5vZGQ7c3Ryb2tlLXdpZHRoOjBweDt9PC9zdHlsZT48L2RlZnM+PHBhdGggZD0iTTE3LjMsMTcuNWwxNS41LDl2MThsLTE1LjUtOXYtMThaIiBjbGFzcz0iY2xzLTEiLz48cGF0aCBkPSJNMzQuNSwyNi41djE4bDE1LjUtOXYtMThsLTE1LjUsOVoiIGNsYXNzPSJjbHMtMSIvPjxwYXRoIGQ9Ik0wLDcuNXYxOGwxNS41LDl2LTE4TDAsNy41WiIgY2xhc3M9ImNscy0xIi8+PHBhdGggZD0iTTE3LjMsNTUuNWwxNS41LDl2LTE4bC0xNS41LTl2MThaIiBjbGFzcz0iY2xzLTEiLz48L3N2Zz4=;" vertex="1" parent="_ASd7ttjQse1Z8Tchp8T-1">
                    <mxGeometry x="502" y="486" width="50" height="57" as="geometry"/>
                </mxCell>
                <mxCell id="_ASd7ttjQse1Z8Tchp8T-14" value="Developer A" style="sketch=0;outlineConnect=0;fontColor=#232F3E;gradientColor=none;fillColor=#232F3D;strokeColor=none;dashed=0;verticalLabelPosition=bottom;verticalAlign=top;align=center;html=1;fontSize=12;fontStyle=0;aspect=fixed;pointerEvents=1;shape=mxgraph.aws4.user;" vertex="1" parent="_ASd7ttjQse1Z8Tchp8T-1">
                    <mxGeometry x="82" y="495" width="39" height="39" as="geometry"/>
                </mxCell>
                <mxCell id="_ASd7ttjQse1Z8Tchp8T-15" style="edgeStyle=none;html=1;" edge="1" parent="_ASd7ttjQse1Z8Tchp8T-1" source="_ASd7ttjQse1Z8Tchp8T-16" target="_ASd7ttjQse1Z8Tchp8T-17">
                    <mxGeometry relative="1" as="geometry"/>
                </mxCell>
                <mxCell id="_ASd7ttjQse1Z8Tchp8T-16" value="Terraform&amp;nbsp;&lt;span style=&quot;background-color: transparent;&quot;&gt;Files&lt;/span&gt;" style="sketch=0;outlineConnect=0;fontColor=#232F3E;gradientColor=none;fillColor=#232F3D;strokeColor=none;dashed=0;verticalLabelPosition=bottom;verticalAlign=top;align=center;html=1;fontSize=12;fontStyle=0;aspect=fixed;pointerEvents=1;shape=mxgraph.aws4.documents3;" vertex="1" parent="_ASd7ttjQse1Z8Tchp8T-1">
                    <mxGeometry x="272" y="486" width="35.81" height="49" as="geometry"/>
                </mxCell>
                <mxCell id="_ASd7ttjQse1Z8Tchp8T-17" value="AWS CLI&amp;nbsp;&lt;span style=&quot;background-color: transparent;&quot;&gt;&amp;amp;&amp;nbsp;&lt;/span&gt;&lt;div&gt;&lt;span style=&quot;background-color: transparent;&quot;&gt;Access Key&lt;/span&gt;&lt;/div&gt;" style="sketch=0;points=[[0,0,0],[0.25,0,0],[0.5,0,0],[0.75,0,0],[1,0,0],[0,1,0],[0.25,1,0],[0.5,1,0],[0.75,1,0],[1,1,0],[0,0.25,0],[0,0.5,0],[0,0.75,0],[1,0.25,0],[1,0.5,0],[1,0.75,0]];points=[[0,0,0],[0.25,0,0],[0.5,0,0],[0.75,0,0],[1,0,0],[0,1,0],[0.25,1,0],[0.5,1,0],[0.75,1,0],[1,1,0],[0,0.25,0],[0,0.5,0],[0,0.75,0],[1,0.25,0],[1,0.5,0],[1,0.75,0]];outlineConnect=0;fontColor=#232F3E;fillColor=#E7157B;strokeColor=#ffffff;dashed=0;verticalLabelPosition=bottom;verticalAlign=top;align=center;html=1;fontSize=12;fontStyle=0;aspect=fixed;shape=mxgraph.aws4.resourceIcon;resIcon=mxgraph.aws4.command_line_interface;" vertex="1" parent="_ASd7ttjQse1Z8Tchp8T-1">
                    <mxGeometry x="392" y="489" width="43" height="43" as="geometry"/>
                </mxCell>
                <mxCell id="_ASd7ttjQse1Z8Tchp8T-18" style="edgeStyle=none;html=1;exitX=1;exitY=0.5;exitDx=0;exitDy=0;exitPerimeter=0;entryX=-0.04;entryY=0.404;entryDx=0;entryDy=0;entryPerimeter=0;" edge="1" parent="_ASd7ttjQse1Z8Tchp8T-1" source="_ASd7ttjQse1Z8Tchp8T-17" target="_ASd7ttjQse1Z8Tchp8T-13">
                    <mxGeometry relative="1" as="geometry"/>
                </mxCell>
                <mxCell id="_ASd7ttjQse1Z8Tchp8T-19" style="edgeStyle=none;html=1;entryX=0.002;entryY=0.467;entryDx=0;entryDy=0;entryPerimeter=0;" edge="1" parent="_ASd7ttjQse1Z8Tchp8T-1" source="_ASd7ttjQse1Z8Tchp8T-14" target="_ASd7ttjQse1Z8Tchp8T-2">
                    <mxGeometry relative="1" as="geometry"/>
                </mxCell>
                <mxCell id="_ASd7ttjQse1Z8Tchp8T-20" value="Local Development Environment" style="fillColor=none;strokeColor=#5A6C86;dashed=1;verticalAlign=top;fontStyle=0;fontColor=#5A6C86;whiteSpace=wrap;html=1;" vertex="1" parent="_ASd7ttjQse1Z8Tchp8T-1">
                    <mxGeometry x="202" y="728" width="430" height="191" as="geometry"/>
                </mxCell>
                <mxCell id="_ASd7ttjQse1Z8Tchp8T-21" style="edgeStyle=none;html=1;exitX=1;exitY=0.5;exitDx=0;exitDy=0;entryX=0;entryY=0.5;entryDx=0;entryDy=0;" edge="1" parent="_ASd7ttjQse1Z8Tchp8T-1" source="_ASd7ttjQse1Z8Tchp8T-22" target="_ASd7ttjQse1Z8Tchp8T-3">
                    <mxGeometry relative="1" as="geometry"/>
                </mxCell>
                <mxCell id="_ASd7ttjQse1Z8Tchp8T-22" value="Terraform CLI" style="shape=image;verticalLabelPosition=bottom;verticalAlign=top;imageAspect=0;aspect=fixed;image=data:image/svg+xml,PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHZpZXdCb3g9IjAgNy41IDUwIDU3IiBoZWlnaHQ9IjU3IiB3aWR0aD0iNTAiIGlkPSJMb2dvcyI+PGRlZnM+PHN0eWxlPi5jbHMtMXtmaWxsOiM3YjQyYmM7ZmlsbC1ydWxlOmV2ZW5vZGQ7c3Ryb2tlLXdpZHRoOjBweDt9PC9zdHlsZT48L2RlZnM+PHBhdGggZD0iTTE3LjMsMTcuNWwxNS41LDl2MThsLTE1LjUtOXYtMThaIiBjbGFzcz0iY2xzLTEiLz48cGF0aCBkPSJNMzQuNSwyNi41djE4bDE1LjUtOXYtMThsLTE1LjUsOVoiIGNsYXNzPSJjbHMtMSIvPjxwYXRoIGQ9Ik0wLDcuNXYxOGwxNS41LDl2LTE4TDAsNy41WiIgY2xhc3M9ImNscy0xIi8+PHBhdGggZD0iTTE3LjMsNTUuNWwxNS41LDl2LTE4bC0xNS41LTl2MThaIiBjbGFzcz0iY2xzLTEiLz48L3N2Zz4=;" vertex="1" parent="_ASd7ttjQse1Z8Tchp8T-1">
                    <mxGeometry x="502" y="791" width="50" height="57" as="geometry"/>
                </mxCell>
                <mxCell id="_ASd7ttjQse1Z8Tchp8T-23" value="Developer B" style="sketch=0;outlineConnect=0;fontColor=#232F3E;gradientColor=none;fillColor=#232F3D;strokeColor=none;dashed=0;verticalLabelPosition=bottom;verticalAlign=top;align=center;html=1;fontSize=12;fontStyle=0;aspect=fixed;pointerEvents=1;shape=mxgraph.aws4.user;" vertex="1" parent="_ASd7ttjQse1Z8Tchp8T-1">
                    <mxGeometry x="75" y="798" width="39" height="39" as="geometry"/>
                </mxCell>
                <mxCell id="_ASd7ttjQse1Z8Tchp8T-24" style="edgeStyle=none;html=1;" edge="1" parent="_ASd7ttjQse1Z8Tchp8T-1" source="_ASd7ttjQse1Z8Tchp8T-25" target="_ASd7ttjQse1Z8Tchp8T-26">
                    <mxGeometry relative="1" as="geometry"/>
                </mxCell>
                <mxCell id="_ASd7ttjQse1Z8Tchp8T-25" value="Terraform&amp;nbsp;&lt;span style=&quot;background-color: transparent;&quot;&gt;Files&lt;/span&gt;" style="sketch=0;outlineConnect=0;fontColor=#232F3E;gradientColor=none;fillColor=#232F3D;strokeColor=none;dashed=0;verticalLabelPosition=bottom;verticalAlign=top;align=center;html=1;fontSize=12;fontStyle=0;aspect=fixed;pointerEvents=1;shape=mxgraph.aws4.documents3;" vertex="1" parent="_ASd7ttjQse1Z8Tchp8T-1">
                    <mxGeometry x="272" y="791" width="35.81" height="49" as="geometry"/>
                </mxCell>
                <mxCell id="_ASd7ttjQse1Z8Tchp8T-26" value="AWS CLI&amp;nbsp;&lt;span style=&quot;background-color: transparent;&quot;&gt;&amp;amp;&amp;nbsp;&lt;/span&gt;&lt;div&gt;&lt;span style=&quot;background-color: transparent;&quot;&gt;Access Key&lt;/span&gt;&lt;/div&gt;" style="sketch=0;points=[[0,0,0],[0.25,0,0],[0.5,0,0],[0.75,0,0],[1,0,0],[0,1,0],[0.25,1,0],[0.5,1,0],[0.75,1,0],[1,1,0],[0,0.25,0],[0,0.5,0],[0,0.75,0],[1,0.25,0],[1,0.5,0],[1,0.75,0]];points=[[0,0,0],[0.25,0,0],[0.5,0,0],[0.75,0,0],[1,0,0],[0,1,0],[0.25,1,0],[0.5,1,0],[0.75,1,0],[1,1,0],[0,0.25,0],[0,0.5,0],[0,0.75,0],[1,0.25,0],[1,0.5,0],[1,0.75,0]];outlineConnect=0;fontColor=#232F3E;fillColor=#E7157B;strokeColor=#ffffff;dashed=0;verticalLabelPosition=bottom;verticalAlign=top;align=center;html=1;fontSize=12;fontStyle=0;aspect=fixed;shape=mxgraph.aws4.resourceIcon;resIcon=mxgraph.aws4.command_line_interface;" vertex="1" parent="_ASd7ttjQse1Z8Tchp8T-1">
                    <mxGeometry x="392" y="794" width="43" height="43" as="geometry"/>
                </mxCell>
                <mxCell id="_ASd7ttjQse1Z8Tchp8T-27" style="edgeStyle=none;html=1;exitX=1;exitY=0.5;exitDx=0;exitDy=0;exitPerimeter=0;entryX=-0.04;entryY=0.404;entryDx=0;entryDy=0;entryPerimeter=0;" edge="1" parent="_ASd7ttjQse1Z8Tchp8T-1" source="_ASd7ttjQse1Z8Tchp8T-26" target="_ASd7ttjQse1Z8Tchp8T-22">
                    <mxGeometry relative="1" as="geometry"/>
                </mxCell>
                <mxCell id="_ASd7ttjQse1Z8Tchp8T-28" style="edgeStyle=none;html=1;entryX=0.002;entryY=0.467;entryDx=0;entryDy=0;entryPerimeter=0;" edge="1" parent="_ASd7ttjQse1Z8Tchp8T-1" source="_ASd7ttjQse1Z8Tchp8T-23" target="_ASd7ttjQse1Z8Tchp8T-20">
                    <mxGeometry relative="1" as="geometry"/>
                </mxCell>
                <mxCell id="ByG2kk1BWm8WUh_A17BU-0" value="tf-aws-setup-maturity-lvl-0-solution-remote-backend.png" style="text;" vertex="1" parent="_ASd7ttjQse1Z8Tchp8T-1">
                    <mxGeometry x="19.640963040865245" y="86.25639460637012" width="315" height="26" as="geometry"/>
                </mxCell>
            </root>
        </mxGraphModel>
    </diagram>
    <diagram id="q5pSxBfpz4YL3xW1C_LK" name="tf-aws-setup-maturity-level-0-problem">
        <mxGraphModel dx="1057" dy="711" grid="0" gridSize="10" guides="1" tooltips="1" connect="1" arrows="1" fold="1" page="0" pageScale="1" pageWidth="1100" pageHeight="850" background="#ffffff" math="0" shadow="0">
            <root>
                <mxCell id="0"/>
                <mxCell id="1" parent="0"/>
                <mxCell id="9" value="Local Development Environment" style="fillColor=none;strokeColor=#5A6C86;dashed=1;verticalAlign=top;fontStyle=0;fontColor=#5A6C86;whiteSpace=wrap;html=1;" parent="1" vertex="1">
                    <mxGeometry x="154" y="287" width="430" height="270" as="geometry"/>
                </mxCell>
                <mxCell id="2" value="AWS Account" style="points=[[0,0],[0.25,0],[0.5,0],[0.75,0],[1,0],[1,0.25],[1,0.5],[1,0.75],[1,1],[0.75,1],[0.5,1],[0.25,1],[0,1],[0,0.75],[0,0.5],[0,0.25]];outlineConnect=0;gradientColor=none;html=1;whiteSpace=wrap;fontSize=12;fontStyle=0;container=1;pointerEvents=0;collapsible=0;recursiveResize=0;shape=mxgraph.aws4.group;grIcon=mxgraph.aws4.group_account;strokeColor=#CD2264;fillColor=none;verticalAlign=top;align=left;spacingLeft=30;fontColor=#CD2264;dashed=0;" parent="1" vertex="1">
                    <mxGeometry x="767" y="407" width="320" height="240" as="geometry"/>
                </mxCell>
                <mxCell id="5" value="eu-north-1" style="points=[[0,0],[0.25,0],[0.5,0],[0.75,0],[1,0],[1,0.25],[1,0.5],[1,0.75],[1,1],[0.75,1],[0.5,1],[0.25,1],[0,1],[0,0.75],[0,0.5],[0,0.25]];outlineConnect=0;gradientColor=none;html=1;whiteSpace=wrap;fontSize=12;fontStyle=0;container=1;pointerEvents=0;collapsible=0;recursiveResize=0;shape=mxgraph.aws4.group;grIcon=mxgraph.aws4.group_region;strokeColor=#00A4A6;fillColor=none;verticalAlign=top;align=left;spacingLeft=30;fontColor=#147EBA;dashed=1;" parent="2" vertex="1">
                    <mxGeometry x="40" y="40" width="220" height="160" as="geometry"/>
                </mxCell>
                <mxCell id="13" value="&lt;div&gt;&lt;span style=&quot;color: rgb(63, 63, 63); font-family: Helvetica; font-size: 12px; font-style: normal; font-variant-ligatures: normal; font-variant-caps: normal; font-weight: 400; letter-spacing: normal; orphans: 2; text-align: center; text-indent: 0px; text-transform: none; widows: 2; word-spacing: 0px; -webkit-text-stroke-width: 0px; white-space: nowrap; background-color: rgb(251, 251, 251); text-decoration-thickness: initial; text-decoration-style: initial; text-decoration-color: initial; float: none; display: inline !important;&quot;&gt;S3 Bucket&lt;/span&gt;&lt;/div&gt;&lt;span style=&quot;color: rgb(63, 63, 63); font-family: Helvetica; font-size: 12px; font-style: normal; font-variant-ligatures: normal; font-variant-caps: normal; font-weight: 400; letter-spacing: normal; orphans: 2; text-align: center; text-indent: 0px; text-transform: none; widows: 2; word-spacing: 0px; -webkit-text-stroke-width: 0px; white-space: nowrap; background-color: rgb(251, 251, 251); text-decoration-thickness: initial; text-decoration-style: initial; text-decoration-color: initial; float: none; display: inline !important;&quot;&gt;my-tf-test-x&lt;/span&gt;" style="sketch=0;outlineConnect=0;fontColor=#232F3E;gradientColor=none;fillColor=#7AA116;strokeColor=none;dashed=0;verticalLabelPosition=bottom;verticalAlign=top;align=center;html=1;fontSize=12;fontStyle=0;aspect=fixed;pointerEvents=1;shape=mxgraph.aws4.bucket;" parent="5" vertex="1">
                    <mxGeometry x="91.73" y="66" width="36.54" height="38" as="geometry"/>
                </mxCell>
                <mxCell id="21" style="edgeStyle=none;html=1;entryX=0;entryY=0.5;entryDx=0;entryDy=0;" parent="1" source="6" target="2" edge="1">
                    <mxGeometry relative="1" as="geometry"/>
                </mxCell>
                <mxCell id="24" style="edgeStyle=none;html=1;shadow=0;strokeColor=default;endArrow=none;endFill=0;dashed=1;" parent="1" source="6" target="23" edge="1">
                    <mxGeometry relative="1" as="geometry"/>
                </mxCell>
                <mxCell id="6" value="Terraform CLI" style="shape=image;verticalLabelPosition=bottom;verticalAlign=top;imageAspect=0;aspect=fixed;image=data:image/svg+xml,PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHZpZXdCb3g9IjAgNy41IDUwIDU3IiBoZWlnaHQ9IjU3IiB3aWR0aD0iNTAiIGlkPSJMb2dvcyI+PGRlZnM+PHN0eWxlPi5jbHMtMXtmaWxsOiM3YjQyYmM7ZmlsbC1ydWxlOmV2ZW5vZGQ7c3Ryb2tlLXdpZHRoOjBweDt9PC9zdHlsZT48L2RlZnM+PHBhdGggZD0iTTE3LjMsMTcuNWwxNS41LDl2MThsLTE1LjUtOXYtMThaIiBjbGFzcz0iY2xzLTEiLz48cGF0aCBkPSJNMzQuNSwyNi41djE4bDE1LjUtOXYtMThsLTE1LjUsOVoiIGNsYXNzPSJjbHMtMSIvPjxwYXRoIGQ9Ik0wLDcuNXYxOGwxNS41LDl2LTE4TDAsNy41WiIgY2xhc3M9ImNscy0xIi8+PHBhdGggZD0iTTE3LjMsNTUuNWwxNS41LDl2LTE4bC0xNS41LTl2MThaIiBjbGFzcz0iY2xzLTEiLz48L3N2Zz4=;" parent="1" vertex="1">
                    <mxGeometry x="454" y="350" width="50" height="57" as="geometry"/>
                </mxCell>
                <mxCell id="7" value="Developer A" style="sketch=0;outlineConnect=0;fontColor=#232F3E;gradientColor=none;fillColor=#232F3D;strokeColor=none;dashed=0;verticalLabelPosition=bottom;verticalAlign=top;align=center;html=1;fontSize=12;fontStyle=0;aspect=fixed;pointerEvents=1;shape=mxgraph.aws4.user;" parent="1" vertex="1">
                    <mxGeometry x="34" y="393" width="39" height="39" as="geometry"/>
                </mxCell>
                <mxCell id="19" style="edgeStyle=none;html=1;" parent="1" source="10" target="18" edge="1">
                    <mxGeometry relative="1" as="geometry"/>
                </mxCell>
                <mxCell id="10" value="Terraform&amp;nbsp;&lt;span style=&quot;background-color: transparent;&quot;&gt;Files&lt;/span&gt;" style="sketch=0;outlineConnect=0;fontColor=#232F3E;gradientColor=none;fillColor=#232F3D;strokeColor=none;dashed=0;verticalLabelPosition=bottom;verticalAlign=top;align=center;html=1;fontSize=12;fontStyle=0;aspect=fixed;pointerEvents=1;shape=mxgraph.aws4.documents3;" parent="1" vertex="1">
                    <mxGeometry x="224" y="350" width="35.81" height="49" as="geometry"/>
                </mxCell>
                <mxCell id="18" value="AWS CLI&amp;nbsp;&lt;span style=&quot;background-color: transparent;&quot;&gt;&amp;amp;&amp;nbsp;&lt;/span&gt;&lt;div&gt;&lt;span style=&quot;background-color: transparent;&quot;&gt;Access Key&lt;/span&gt;&lt;/div&gt;" style="sketch=0;points=[[0,0,0],[0.25,0,0],[0.5,0,0],[0.75,0,0],[1,0,0],[0,1,0],[0.25,1,0],[0.5,1,0],[0.75,1,0],[1,1,0],[0,0.25,0],[0,0.5,0],[0,0.75,0],[1,0.25,0],[1,0.5,0],[1,0.75,0]];points=[[0,0,0],[0.25,0,0],[0.5,0,0],[0.75,0,0],[1,0,0],[0,1,0],[0.25,1,0],[0.5,1,0],[0.75,1,0],[1,1,0],[0,0.25,0],[0,0.5,0],[0,0.75,0],[1,0.25,0],[1,0.5,0],[1,0.75,0]];outlineConnect=0;fontColor=#232F3E;fillColor=#E7157B;strokeColor=#ffffff;dashed=0;verticalLabelPosition=bottom;verticalAlign=top;align=center;html=1;fontSize=12;fontStyle=0;aspect=fixed;shape=mxgraph.aws4.resourceIcon;resIcon=mxgraph.aws4.command_line_interface;" parent="1" vertex="1">
                    <mxGeometry x="344" y="353" width="43" height="43" as="geometry"/>
                </mxCell>
                <mxCell id="20" style="edgeStyle=none;html=1;exitX=1;exitY=0.5;exitDx=0;exitDy=0;exitPerimeter=0;entryX=-0.04;entryY=0.404;entryDx=0;entryDy=0;entryPerimeter=0;" parent="1" source="18" target="6" edge="1">
                    <mxGeometry relative="1" as="geometry"/>
                </mxCell>
                <mxCell id="22" style="edgeStyle=none;html=1;entryX=0.002;entryY=0.467;entryDx=0;entryDy=0;entryPerimeter=0;" parent="1" source="7" target="9" edge="1">
                    <mxGeometry relative="1" as="geometry"/>
                </mxCell>
                <mxCell id="23" value="terraform.tfstate" style="sketch=0;outlineConnect=0;fontColor=#232F3E;gradientColor=none;fillColor=#232F3D;strokeColor=none;dashed=0;verticalLabelPosition=bottom;verticalAlign=top;align=center;html=1;fontSize=12;fontStyle=0;aspect=fixed;pointerEvents=1;shape=mxgraph.aws4.document;" parent="1" vertex="1">
                    <mxGeometry x="462.66" y="453" width="29.96" height="41" as="geometry"/>
                </mxCell>
                <mxCell id="40" value="Local Development Environment" style="fillColor=none;strokeColor=#5A6C86;dashed=1;verticalAlign=top;fontStyle=0;fontColor=#5A6C86;whiteSpace=wrap;html=1;" parent="1" vertex="1">
                    <mxGeometry x="154" y="592" width="430" height="270" as="geometry"/>
                </mxCell>
                <mxCell id="41" style="edgeStyle=none;html=1;shadow=0;strokeColor=default;endArrow=none;endFill=0;dashed=1;" parent="1" source="42" target="49" edge="1">
                    <mxGeometry relative="1" as="geometry"/>
                </mxCell>
                <mxCell id="50" style="edgeStyle=none;html=1;exitX=1;exitY=0.5;exitDx=0;exitDy=0;entryX=0;entryY=0.5;entryDx=0;entryDy=0;" parent="1" source="42" target="2" edge="1">
                    <mxGeometry relative="1" as="geometry"/>
                </mxCell>
                <mxCell id="42" value="Terraform CLI" style="shape=image;verticalLabelPosition=bottom;verticalAlign=top;imageAspect=0;aspect=fixed;image=data:image/svg+xml,PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHZpZXdCb3g9IjAgNy41IDUwIDU3IiBoZWlnaHQ9IjU3IiB3aWR0aD0iNTAiIGlkPSJMb2dvcyI+PGRlZnM+PHN0eWxlPi5jbHMtMXtmaWxsOiM3YjQyYmM7ZmlsbC1ydWxlOmV2ZW5vZGQ7c3Ryb2tlLXdpZHRoOjBweDt9PC9zdHlsZT48L2RlZnM+PHBhdGggZD0iTTE3LjMsMTcuNWwxNS41LDl2MThsLTE1LjUtOXYtMThaIiBjbGFzcz0iY2xzLTEiLz48cGF0aCBkPSJNMzQuNSwyNi41djE4bDE1LjUtOXYtMThsLTE1LjUsOVoiIGNsYXNzPSJjbHMtMSIvPjxwYXRoIGQ9Ik0wLDcuNXYxOGwxNS41LDl2LTE4TDAsNy41WiIgY2xhc3M9ImNscy0xIi8+PHBhdGggZD0iTTE3LjMsNTUuNWwxNS41LDl2LTE4bC0xNS41LTl2MThaIiBjbGFzcz0iY2xzLTEiLz48L3N2Zz4=;" parent="1" vertex="1">
                    <mxGeometry x="454" y="655" width="50" height="57" as="geometry"/>
                </mxCell>
                <mxCell id="43" value="Developer B" style="sketch=0;outlineConnect=0;fontColor=#232F3E;gradientColor=none;fillColor=#232F3D;strokeColor=none;dashed=0;verticalLabelPosition=bottom;verticalAlign=top;align=center;html=1;fontSize=12;fontStyle=0;aspect=fixed;pointerEvents=1;shape=mxgraph.aws4.user;" parent="1" vertex="1">
                    <mxGeometry x="34" y="698" width="39" height="39" as="geometry"/>
                </mxCell>
                <mxCell id="44" style="edgeStyle=none;html=1;" parent="1" source="45" target="46" edge="1">
                    <mxGeometry relative="1" as="geometry"/>
                </mxCell>
                <mxCell id="45" value="Terraform&amp;nbsp;&lt;span style=&quot;background-color: transparent;&quot;&gt;Files&lt;/span&gt;" style="sketch=0;outlineConnect=0;fontColor=#232F3E;gradientColor=none;fillColor=#232F3D;strokeColor=none;dashed=0;verticalLabelPosition=bottom;verticalAlign=top;align=center;html=1;fontSize=12;fontStyle=0;aspect=fixed;pointerEvents=1;shape=mxgraph.aws4.documents3;" parent="1" vertex="1">
                    <mxGeometry x="224" y="655" width="35.81" height="49" as="geometry"/>
                </mxCell>
                <mxCell id="46" value="AWS CLI&amp;nbsp;&lt;span style=&quot;background-color: transparent;&quot;&gt;&amp;amp;&amp;nbsp;&lt;/span&gt;&lt;div&gt;&lt;span style=&quot;background-color: transparent;&quot;&gt;Access Key&lt;/span&gt;&lt;/div&gt;" style="sketch=0;points=[[0,0,0],[0.25,0,0],[0.5,0,0],[0.75,0,0],[1,0,0],[0,1,0],[0.25,1,0],[0.5,1,0],[0.75,1,0],[1,1,0],[0,0.25,0],[0,0.5,0],[0,0.75,0],[1,0.25,0],[1,0.5,0],[1,0.75,0]];points=[[0,0,0],[0.25,0,0],[0.5,0,0],[0.75,0,0],[1,0,0],[0,1,0],[0.25,1,0],[0.5,1,0],[0.75,1,0],[1,1,0],[0,0.25,0],[0,0.5,0],[0,0.75,0],[1,0.25,0],[1,0.5,0],[1,0.75,0]];outlineConnect=0;fontColor=#232F3E;fillColor=#E7157B;strokeColor=#ffffff;dashed=0;verticalLabelPosition=bottom;verticalAlign=top;align=center;html=1;fontSize=12;fontStyle=0;aspect=fixed;shape=mxgraph.aws4.resourceIcon;resIcon=mxgraph.aws4.command_line_interface;" parent="1" vertex="1">
                    <mxGeometry x="344" y="658" width="43" height="43" as="geometry"/>
                </mxCell>
                <mxCell id="47" style="edgeStyle=none;html=1;exitX=1;exitY=0.5;exitDx=0;exitDy=0;exitPerimeter=0;entryX=-0.04;entryY=0.404;entryDx=0;entryDy=0;entryPerimeter=0;" parent="1" source="46" target="42" edge="1">
                    <mxGeometry relative="1" as="geometry"/>
                </mxCell>
                <mxCell id="48" style="edgeStyle=none;html=1;entryX=0.002;entryY=0.467;entryDx=0;entryDy=0;entryPerimeter=0;" parent="1" source="43" target="40" edge="1">
                    <mxGeometry relative="1" as="geometry"/>
                </mxCell>
                <mxCell id="49" value="terraform.tfstate" style="sketch=0;outlineConnect=0;fontColor=#232F3E;gradientColor=none;fillColor=#232F3D;strokeColor=none;dashed=0;verticalLabelPosition=bottom;verticalAlign=top;align=center;html=1;fontSize=12;fontStyle=0;aspect=fixed;pointerEvents=1;shape=mxgraph.aws4.document;" parent="1" vertex="1">
                    <mxGeometry x="462.66" y="758" width="29.96" height="41" as="geometry"/>
                </mxCell>
                <mxCell id="53" value="&lt;div style=&quot;&quot;&gt;&lt;span style=&quot;background-color: transparent;&quot;&gt;&lt;font&gt;&lt;font style=&quot;color: rgb(255, 0, 0);&quot;&gt;Problem&lt;/font&gt;: developers cannot work on the same infrastructure as they don&#39;t have access to the same State File.&lt;/font&gt;&lt;/span&gt;&lt;/div&gt;" style="shape=note;size=20;whiteSpace=wrap;html=1;align=center;" parent="1" vertex="1">
                    <mxGeometry x="767" y="703" width="180" height="121" as="geometry"/>
                </mxCell>
                <mxCell id="56" value="&lt;div style=&quot;&quot;&gt;&lt;span style=&quot;background-color: transparent;&quot;&gt;&lt;font&gt;&lt;font style=&quot;color: rgb(0, 153, 0);&quot;&gt;Solution&lt;/font&gt;: a shared location where the State File is stored and can be accessed by developers and or machine users.&lt;/font&gt;&lt;/span&gt;&lt;/div&gt;" style="shape=note;size=20;whiteSpace=wrap;html=1;align=center;" parent="1" vertex="1">
                    <mxGeometry x="969" y="701" width="180" height="121" as="geometry"/>
                </mxCell>
            </root>
        </mxGraphModel>
    </diagram>
    <diagram id="PkhosA4qJehzKThrB8xl" name="tf-aws-setup-maturiy-level-0">
        <mxGraphModel dx="1057" dy="711" grid="0" gridSize="10" guides="1" tooltips="1" connect="1" arrows="1" fold="1" page="0" pageScale="1" pageWidth="1100" pageHeight="850" background="#ffffff" math="0" shadow="0">
            <root>
                <mxCell id="0"/>
                <mxCell id="1" parent="0"/>
                <mxCell id="BXp47FkMODcyS4w8nFmD-1" value="Local Development Environment" style="fillColor=none;strokeColor=#5A6C86;dashed=1;verticalAlign=top;fontStyle=0;fontColor=#5A6C86;whiteSpace=wrap;html=1;" parent="1" vertex="1">
                    <mxGeometry x="154" y="287" width="430" height="270" as="geometry"/>
                </mxCell>
                <mxCell id="BXp47FkMODcyS4w8nFmD-2" value="AWS Account" style="points=[[0,0],[0.25,0],[0.5,0],[0.75,0],[1,0],[1,0.25],[1,0.5],[1,0.75],[1,1],[0.75,1],[0.5,1],[0.25,1],[0,1],[0,0.75],[0,0.5],[0,0.25]];outlineConnect=0;gradientColor=none;html=1;whiteSpace=wrap;fontSize=12;fontStyle=0;container=1;pointerEvents=0;collapsible=0;recursiveResize=0;shape=mxgraph.aws4.group;grIcon=mxgraph.aws4.group_account;strokeColor=#CD2264;fillColor=none;verticalAlign=top;align=left;spacingLeft=30;fontColor=#CD2264;dashed=0;" parent="1" vertex="1">
                    <mxGeometry x="684" y="257" width="320" height="240" as="geometry"/>
                </mxCell>
                <mxCell id="BXp47FkMODcyS4w8nFmD-3" value="eu-north-1" style="points=[[0,0],[0.25,0],[0.5,0],[0.75,0],[1,0],[1,0.25],[1,0.5],[1,0.75],[1,1],[0.75,1],[0.5,1],[0.25,1],[0,1],[0,0.75],[0,0.5],[0,0.25]];outlineConnect=0;gradientColor=none;html=1;whiteSpace=wrap;fontSize=12;fontStyle=0;container=1;pointerEvents=0;collapsible=0;recursiveResize=0;shape=mxgraph.aws4.group;grIcon=mxgraph.aws4.group_region;strokeColor=#00A4A6;fillColor=none;verticalAlign=top;align=left;spacingLeft=30;fontColor=#147EBA;dashed=1;" parent="BXp47FkMODcyS4w8nFmD-2" vertex="1">
                    <mxGeometry x="40" y="40" width="220" height="160" as="geometry"/>
                </mxCell>
                <mxCell id="BXp47FkMODcyS4w8nFmD-4" value="&lt;div&gt;&lt;span style=&quot;color: rgb(63, 63, 63); font-family: Helvetica; font-size: 12px; font-style: normal; font-variant-ligatures: normal; font-variant-caps: normal; font-weight: 400; letter-spacing: normal; orphans: 2; text-align: center; text-indent: 0px; text-transform: none; widows: 2; word-spacing: 0px; -webkit-text-stroke-width: 0px; white-space: nowrap; background-color: rgb(251, 251, 251); text-decoration-thickness: initial; text-decoration-style: initial; text-decoration-color: initial; float: none; display: inline !important;&quot;&gt;S3 Bucket&lt;/span&gt;&lt;/div&gt;&lt;span style=&quot;color: rgb(63, 63, 63); font-family: Helvetica; font-size: 12px; font-style: normal; font-variant-ligatures: normal; font-variant-caps: normal; font-weight: 400; letter-spacing: normal; orphans: 2; text-align: center; text-indent: 0px; text-transform: none; widows: 2; word-spacing: 0px; -webkit-text-stroke-width: 0px; white-space: nowrap; background-color: rgb(251, 251, 251); text-decoration-thickness: initial; text-decoration-style: initial; text-decoration-color: initial; float: none; display: inline !important;&quot;&gt;my-tf-test-x&lt;/span&gt;" style="sketch=0;outlineConnect=0;fontColor=#232F3E;gradientColor=none;fillColor=#7AA116;strokeColor=none;dashed=0;verticalLabelPosition=bottom;verticalAlign=top;align=center;html=1;fontSize=12;fontStyle=0;aspect=fixed;pointerEvents=1;shape=mxgraph.aws4.bucket;" parent="BXp47FkMODcyS4w8nFmD-3" vertex="1">
                    <mxGeometry x="91.73" y="66" width="36.54" height="38" as="geometry"/>
                </mxCell>
                <mxCell id="BXp47FkMODcyS4w8nFmD-5" style="edgeStyle=none;html=1;entryX=0;entryY=0.5;entryDx=0;entryDy=0;" parent="1" source="BXp47FkMODcyS4w8nFmD-7" target="BXp47FkMODcyS4w8nFmD-2" edge="1">
                    <mxGeometry relative="1" as="geometry"/>
                </mxCell>
                <mxCell id="BXp47FkMODcyS4w8nFmD-6" style="edgeStyle=none;html=1;shadow=0;strokeColor=default;endArrow=none;endFill=0;dashed=1;" parent="1" source="BXp47FkMODcyS4w8nFmD-7" target="BXp47FkMODcyS4w8nFmD-14" edge="1">
                    <mxGeometry relative="1" as="geometry"/>
                </mxCell>
                <mxCell id="BXp47FkMODcyS4w8nFmD-7" value="Terraform CLI" style="shape=image;verticalLabelPosition=bottom;verticalAlign=top;imageAspect=0;aspect=fixed;image=data:image/svg+xml,PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHZpZXdCb3g9IjAgNy41IDUwIDU3IiBoZWlnaHQ9IjU3IiB3aWR0aD0iNTAiIGlkPSJMb2dvcyI+PGRlZnM+PHN0eWxlPi5jbHMtMXtmaWxsOiM3YjQyYmM7ZmlsbC1ydWxlOmV2ZW5vZGQ7c3Ryb2tlLXdpZHRoOjBweDt9PC9zdHlsZT48L2RlZnM+PHBhdGggZD0iTTE3LjMsMTcuNWwxNS41LDl2MThsLTE1LjUtOXYtMThaIiBjbGFzcz0iY2xzLTEiLz48cGF0aCBkPSJNMzQuNSwyNi41djE4bDE1LjUtOXYtMThsLTE1LjUsOVoiIGNsYXNzPSJjbHMtMSIvPjxwYXRoIGQ9Ik0wLDcuNXYxOGwxNS41LDl2LTE4TDAsNy41WiIgY2xhc3M9ImNscy0xIi8+PHBhdGggZD0iTTE3LjMsNTUuNWwxNS41LDl2LTE4bC0xNS41LTl2MThaIiBjbGFzcz0iY2xzLTEiLz48L3N2Zz4=;" parent="1" vertex="1">
                    <mxGeometry x="454" y="350" width="50" height="57" as="geometry"/>
                </mxCell>
                <mxCell id="BXp47FkMODcyS4w8nFmD-8" value="Developer" style="sketch=0;outlineConnect=0;fontColor=#232F3E;gradientColor=none;fillColor=#232F3D;strokeColor=none;dashed=0;verticalLabelPosition=bottom;verticalAlign=top;align=center;html=1;fontSize=12;fontStyle=0;aspect=fixed;pointerEvents=1;shape=mxgraph.aws4.user;" parent="1" vertex="1">
                    <mxGeometry x="34" y="393" width="39" height="39" as="geometry"/>
                </mxCell>
                <mxCell id="BXp47FkMODcyS4w8nFmD-9" style="edgeStyle=none;html=1;" parent="1" source="BXp47FkMODcyS4w8nFmD-10" target="BXp47FkMODcyS4w8nFmD-11" edge="1">
                    <mxGeometry relative="1" as="geometry"/>
                </mxCell>
                <mxCell id="BXp47FkMODcyS4w8nFmD-10" value="Terraform&amp;nbsp;&lt;span style=&quot;background-color: transparent;&quot;&gt;Files&lt;/span&gt;" style="sketch=0;outlineConnect=0;fontColor=#232F3E;gradientColor=none;fillColor=#232F3D;strokeColor=none;dashed=0;verticalLabelPosition=bottom;verticalAlign=top;align=center;html=1;fontSize=12;fontStyle=0;aspect=fixed;pointerEvents=1;shape=mxgraph.aws4.documents3;" parent="1" vertex="1">
                    <mxGeometry x="224" y="350" width="35.81" height="49" as="geometry"/>
                </mxCell>
                <mxCell id="BXp47FkMODcyS4w8nFmD-11" value="AWS CLI&amp;nbsp;&lt;span style=&quot;background-color: transparent;&quot;&gt;&amp;amp;&amp;nbsp;&lt;/span&gt;&lt;div&gt;&lt;span style=&quot;background-color: transparent;&quot;&gt;Access Key&lt;/span&gt;&lt;/div&gt;" style="sketch=0;points=[[0,0,0],[0.25,0,0],[0.5,0,0],[0.75,0,0],[1,0,0],[0,1,0],[0.25,1,0],[0.5,1,0],[0.75,1,0],[1,1,0],[0,0.25,0],[0,0.5,0],[0,0.75,0],[1,0.25,0],[1,0.5,0],[1,0.75,0]];points=[[0,0,0],[0.25,0,0],[0.5,0,0],[0.75,0,0],[1,0,0],[0,1,0],[0.25,1,0],[0.5,1,0],[0.75,1,0],[1,1,0],[0,0.25,0],[0,0.5,0],[0,0.75,0],[1,0.25,0],[1,0.5,0],[1,0.75,0]];outlineConnect=0;fontColor=#232F3E;fillColor=#E7157B;strokeColor=#ffffff;dashed=0;verticalLabelPosition=bottom;verticalAlign=top;align=center;html=1;fontSize=12;fontStyle=0;aspect=fixed;shape=mxgraph.aws4.resourceIcon;resIcon=mxgraph.aws4.command_line_interface;" parent="1" vertex="1">
                    <mxGeometry x="344" y="353" width="43" height="43" as="geometry"/>
                </mxCell>
                <mxCell id="BXp47FkMODcyS4w8nFmD-12" style="edgeStyle=none;html=1;exitX=1;exitY=0.5;exitDx=0;exitDy=0;exitPerimeter=0;entryX=-0.04;entryY=0.404;entryDx=0;entryDy=0;entryPerimeter=0;" parent="1" source="BXp47FkMODcyS4w8nFmD-11" target="BXp47FkMODcyS4w8nFmD-7" edge="1">
                    <mxGeometry relative="1" as="geometry"/>
                </mxCell>
                <mxCell id="BXp47FkMODcyS4w8nFmD-13" style="edgeStyle=none;html=1;entryX=0.002;entryY=0.467;entryDx=0;entryDy=0;entryPerimeter=0;" parent="1" source="BXp47FkMODcyS4w8nFmD-8" target="BXp47FkMODcyS4w8nFmD-1" edge="1">
                    <mxGeometry relative="1" as="geometry"/>
                </mxCell>
                <mxCell id="BXp47FkMODcyS4w8nFmD-14" value="terraform.tfstate" style="sketch=0;outlineConnect=0;fontColor=#232F3E;gradientColor=none;fillColor=#232F3D;strokeColor=none;dashed=0;verticalLabelPosition=bottom;verticalAlign=top;align=center;html=1;fontSize=12;fontStyle=0;aspect=fixed;pointerEvents=1;shape=mxgraph.aws4.document;" parent="1" vertex="1">
                    <mxGeometry x="462.66" y="453" width="29.96" height="41" as="geometry"/>
                </mxCell>
            </root>
        </mxGraphModel>
    </diagram>
</mxfile>
````

## File: mlops-course-02/README.md
````markdown
# AWS Infrastructure Setup with Terraform and GitHub Actions

Now that you've provisioned infrastructure resources using Terraform locally, it's time to prepare for real-world collaboration and automation. At maturity level 0, each developer works in isolation, managing their own Terraform state file locally. 

Problem: 
- Collaboration is hard, changes conflict, and there’s a risk of accidental resource changes. 
![tf-aws-setup-maturity-lvl-0-problem](assets/tf-aws-setup-maturity-lvl-0-problem.png)

Solution:
- Use a remote backend for shared Terraform state.
- Manage cloud resources with a dedicated machine user for automation.
- Automate provisioning via GitHub Actions, making infrastructure changes repeatable, auditable, and safe.
![tf-aws-setup-maturity-lvl-0-solution-github-actions](assets/tf-aws-setup-maturity-lvl-0-solution-github-actions.png)

## Prerequisites

* [Terraform](https://developer.hashicorp.com/terraform/downloads)
* [AWS CLI](https://aws.amazon.com/cli/)
* [GitHub](https://docs.github.com/en/get-started/start-your-journey/creating-an-account-on-github)

## 1. Setup Terraform Remote Backend
Before we setup the remote backend for the Terraform state file so that everyone works with the same infrastructure state and have features such as:
- State Locking - prevents concurrent changes
- Versioning - rollback to earlier state if needed
- Encryption - sensitive data in state file is encrypted

We first need to avoid the chicken or the egg problem by provisioning an S3 Bucket to store our Terraform state file. Feel free to use AWS Console (UI), AWS SDKs or CLI. While we're at it we will provision the IAM user (Terraform machine user to be used for automation with GitHub Actions) as well.
```bash
AWS CLI
-------

# Specify the username for the new IAM user
USER_NAME="terraform_user"

# Create IAM User and capture the response
USER_RESPONSE=$(aws iam create-user --user-name "$USER_NAME")

# Check the Amazon Resource Name (ARN) from create-user response.
echo $USER_RESPONSE                                          

# Attach Admin Access Policy to IAM User
aws iam attach-user-policy --user-name "$USER_NAME" --policy-arn arn:aws:iam::aws:policy/AdministratorAccess

# Create Access and Secret Access Keys
CREDS_JSON=$(aws iam create-access-key --user-name "$USER_NAME")

# Check Access and Secret Access Keys from create-access-key response.
echo $CREDS_JSON                                          

# Create S3 Bucket
S3_BUCKET_NAME="tf-remote-backends-ehb"
aws s3 mb "s3://$S3_BUCKET_NAME" --region "eu-north-1"

# Enable Versioning for S3 Bucket
aws s3api put-bucket-versioning --bucket "$S3_BUCKET_NAME" --versioning-configuration Status=Enabled
```
## 2. Improve Project Structure
Organize your infrastructure code for clarity and scalability:
```
mlops-course-02  
├── assets/  
├── docs/  
├── src/  
├── terraform/  
│   ├── backends/  
│   │   ├── dev.conf  
│   │   ├── prd.conf  
│   │   └── tst.conf  
│   ├── environments/  
│   │   ├── dev.tfvars  
│   │   ├── prd.tfvars  
│   │   └── tst.tfvars  
│   ├── modules/  
│   │   └── s3-bucket/  
│   │       ├── locals.tf  
│   │       ├── main.tf  
│   │       ├── outputs.tf  
│   │       ├── variables.tf  
│   │       └── README.md  
│   ├── provider.tf  
│   ├── s3_buckets.tf  
│   └── variables.tf  
├── README.md
```
All Terraform files live under the `terraform/` folder
- Modularization: The new structure introduces Terraform `modules` for reusable, scalable infrastructure components.
- Multiple Environment Support: Separate `environments/dev.tfvars` and `backends/dev.conf` for environment-specific configuration.
- Variable Management: Centralized in `variables.tf`.

## 3. Terraform Configuration
Uses variables for AWS region `var.aws_region` to allow for different environments.
Configures a remote backend `backend "s3" {}` so state is managed in S3, not locally.

`provider.tf`
```hcl
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">=5.97"
    }
  }
  
  backend "s3" {}
}

provider "aws" {
  region = var.aws_region
}
```

Each environment has its own backend configuration file, parameterizing the S3 bucket, state file key, and region.

`backends/{env}.conf`
```terraform
bucket  = "terraform-backends-ehb"
key     = "terraform-{env}.tfstate"
region  = "eu-north-1"
```
All environment-specific or customizable settings (like region, environment, resource delimiter, and S3 buckets) are defined as variables.

`variables.tf`
```hcl
variable "aws_region" {
  description = "AWS region"
  default     = "eu-north-1"
}

variable "environment" {
  description = "Specifies the deployment environment of the resources (e.g., sandbox, dev, tst, acc, prd)"
  type        = string
  default     = "sandbox"
}

variable "delimiter" {
  description = "Resource name delimiter"
  type        = string
  default     = "-"
}

variable "s3_buckets" {
  description = "A list of S3 Buckets"
  type        = list(any)
  default     = []
}
```

Uses a module to define S3 buckets, leveraging the for_each construct to dynamically create as many buckets as you need, with consistent naming and tagging.

`s3_buckets.tf`
```hcl
module "s3_bucket" {
  for_each = { for s3 in var.s3_buckets : s3.key => s3 }
  source   = "./modules/s3-bucket"

  bucket = join(var.delimiter, [each.value.key, var.environment])
  tags   = merge(try(each.value.tags, {}), { environment = var.environment })
}
```

All variable values specific to an environment. Easy switching between dev, test, and prod by changing which tfvars file you use.

`environments/{env}.tfvars`
```hcl
environment = "dev"
location    = "eu-north-1"


s3 = [
  {
    key  = "mlops-course-ehb-data"
    tags = {}
  }
]
```

### 4. Automate with GitHub Actions (CI/CD)
To integrate and automate your Git repository with a CI/CD pipeline for managing infrastucture and other artifacts, you'll typically use service like GitHub Actions, GitLab CI/CD, or Jenkins. Here we will use GitHub Actions.

**Set Up Your AWS Credentials**

1. Create AWS IAM User: In AWS IAM, create a new user with programmatic access and assign appropriate permissions. Store the AWS Access Key ID and Secret Access Key. You’ll need these for your CI/CD pipeline. (already done using AWS CLI)

2. Use Environment Variables: The recommended way to provide AWS credentials to Terraform is through environment variables. Set AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY as environment variables in your CI/CD pipeline settings.

3. GitHub Secrets:
- Store your AWS Access Key and Secret Key in GitHub Secrets. GitHub Secrets provide a secure way to store and manage sensitive information in your GitHub repository.
- In your GitHub repository, go to Settings > Secrets and variables > Actions > Repository secrets and add your AWS credentials as secrets.

**Prepare Your GitHub Repository**

1. Create or Use an Existing Repository: If you haven’t already, create a new GitHub repository or use an existing one for your Terraform code.
2. Push Your Terraform Code: Ensure your Terraform code (.tf files) is in the repository.


**Create GitHub Actions Workflow**

1. Create Workflow Directory: In your repository, create a directory named .github/workflows if it doesn’t already exist.
2. Add Workflow File: Create a new YAML file in the workflows directory (e.g., tf-infra-cicd-dev.yml).
Define Workflow Steps: Edit the YAML file to define the CI/CD steps. Here’s an example:

```YAML
name: tf-infra-cicd-dev

# Controls when the workflow will run
on:
  # Triggers the workflow on push or pull request events but only for the "main" branch
  pull_request:
    branches: [ "main" ]

  # Allows you to run this workflow manually from the Actions tab
  workflow_dispatch:

jobs:
  terraform-validate-plan-apply:
    runs-on: ubuntu-latest
    defaults:
      run:
        working-directory: mlops-course-02/terraform

    steps:
      - name: Checkout repository
        uses: actions/checkout@v4

      - name: Setup Terraform
        uses: hashicorp/setup-terraform@v3

      - name: Configure AWS credentials
        uses: aws-actions/configure-aws-credentials@v4
        with:
          aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
          aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
          aws-region: eu-north-1

      - name: Terraform Format
        run: terraform fmt -check
        continue-on-error: true

      - name: Terraform Init
        run: terraform init --backend-config='backends/dev.conf'

      - name: Terraform Validate
        run: terraform validate -no-color

      - name: Terraform Plan
        run: terraform plan -no-color --var-file='environments/dev.tfvars'

      - name: Terraform Apply
        run: terraform apply --var-file='environments/dev.tfvars' -auto-approve
```

**Push Workflow File to GitHub**

1. Commit the Workflow File: Add the .github/workflows/tf-infra-cicd-dev.yml file to your repository, commit, and push it to GitHub.
```bash
git add .github/workflows/tf-infra-cicd-dev.yml
git commit -m "Add Terraform CI/CD workflow"
git push origin main
```
Verify Actions: Go to the ‘Actions’ tab in your GitHub repository to see the CI/CD pipeline in action after the push.
````

## File: mlops-course-03/src/.dvc/.gitignore
````
/config.local
/tmp
/cache
````

## File: mlops-course-03/src/.dvcignore
````
# Add patterns of files dvc should ignore, which could improve
# the performance. Learn more at
# https://dvc.org/doc/user-guide/dvcignore
````

## File: mlops-course-03/src/data.dvc
````
outs:
- md5: ccb992fa8d129e1b669d1bd27601ab60.dir
  size: 12107105
  nfiles: 2
  hash: md5
  path: data
````

## File: mlops-course-03/src/.gitignore
````
/data
````

## File: mlops-course-03/src/.dvc/config
````
[core]
    remote = storage
['remote "storage"']
    url = s3://mlops-course-ehb-data-dev/data
````
