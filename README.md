## 🚀 Terraform S3 Static Website Hosting

This project demonstrates how to deploy a **static website** on **Amazon S3** using **Terraform**.
The configuration will create a public S3 bucket, upload your website files (`index.html` and `error.html`), and expose the website via an endpoint.

---
🏗️ Architecture
   ## 🏗️ Architecture

```mermaid
flowchart TD
    A[Terraform CLI<br>(Infrastructure as Code)] --> B[AWS Provider]
    B --> C[S3 Bucket<br>(Static Website Hosting)]
    C --> D[Website User<br>(Browser Access)]

```
---

## 📌 Features

* Creates an S3 bucket for static website hosting.
* Configures ownership controls and access policies.
* Enables public read access for all objects.
* Uploads `index.html` and `error.html`.
* Provides the public website URL as an output.

---

## 📂 Project Structure

```
.
├── main.tf          # Terraform configuration
├── index.html       # Homepage file
├── error.html       # Error page file
└── README.md        # Documentation
```

---

## ⚙️ Terraform Code Explanation

### 🔹 Provider and Requirements

```hcl
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}
```

* Uses the AWS provider (`~> 6.0`).
* Deploys resources in **us-east-1 (N. Virginia)**.

---

### 🔹 Create the S3 Bucket

```hcl
resource "aws_s3_bucket" "bucket" {
  bucket = "my-tf-s3-website-bucket"
}
```

* Creates an S3 bucket named `my-tf-s3-website-bucket`.
* Bucket names must be globally unique.

---

### 🔹 Ownership Controls

```hcl
resource "aws_s3_bucket_ownership_controls" "bucket" {
  bucket = aws_s3_bucket.bucket.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}
```

* Ensures objects uploaded are owned by the bucket owner.
* Prevents cross-account ownership issues.

---

### 🔹 Public Access Block

```hcl
resource "aws_s3_bucket_public_access_block" "bucket" {
  bucket = aws_s3_bucket.bucket.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}
```

* Disables AWS’s default public access block.
* Necessary for public website hosting.

---

### 🔹 Bucket ACL

```hcl
resource "aws_s3_bucket_acl" "bucket" {
  depends_on = [
    aws_s3_bucket_ownership_controls.bucket,
    aws_s3_bucket_public_access_block.bucket,
  ]

  bucket = aws_s3_bucket.bucket.id
  acl    = "public-read"
}
```

* Sets the bucket ACL to `public-read`.
* Ensures the bucket can serve public content.

---

### 🔹 Website Configuration

```hcl
resource "aws_s3_bucket_website_configuration" "bucket" {
  bucket = aws_s3_bucket.bucket.id

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "error.html"
  }
}
```

* Enables **static website hosting** on the bucket.
* Defines `index.html` as the main page.
* Defines `error.html` as the error page.

---

### 🔹 Public Read Bucket Policy

```hcl
resource "aws_s3_bucket_policy" "public_read" {
  bucket = aws_s3_bucket.bucket.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "PublicReadGetObject"
        Effect    = "Allow"
        Principal = "*"
        Action    = "s3:GetObject"
        Resource  = "${aws_s3_bucket.bucket.arn}/*"
      }
    ]
  })
}
```

* Allows anyone (`Principal = *`) to read objects inside the bucket.
* Grants public access to files.

---

### 🔹 Upload Website Files

```hcl
resource "aws_s3_object" "index" {
  bucket       = aws_s3_bucket.bucket.id
  key          = "index.html"
  source       = "${path.module}/index.html"
  acl          = "public-read"
  content_type = "text/html"
}

resource "aws_s3_object" "error" {
  bucket       = aws_s3_bucket.bucket.id
  key          = "error.html"
  source       = "${path.module}/error.html"
  acl          = "public-read"
  content_type = "text/html"
}
```

* Uploads `index.html` and `error.html` to the S3 bucket.
* Makes them public and sets the content type to HTML.

---

### 🔹 Output Website URL

```hcl
output "s3_website_url" {
  value = aws_s3_bucket_website_configuration.bucket.website_endpoint
}
```

* Prints the website endpoint after deployment.
* Example output:

  ```
  my-tf-s3-website-bucket.s3-website-us-east-1.amazonaws.com
  ```

---

## 🚀 Deployment Steps

1. Initialize Terraform:

   ```sh
   terraform init
   ```
2. Validate the configuration:

   ```sh
   terraform validate
   ```
3. Apply the configuration:

   ```sh
   terraform apply -auto-approve
   ```
4. Get your website URL from the output:

   ```sh
   terraform output s3_website_url
   ```

---

## 🌐 Accessing the Website

* Open the output URL in your browser.
* Example:

  ```
  http://my-tf-s3-website-bucket.s3-website-us-east-1.amazonaws.com
  ```
* `index.html` will show as the homepage.
* Navigating to a non-existing page will display `error.html`.

---

تحب أزودلك **Diagram بسيط (Architecture)** في الـ README يوضح الـ flow (Terraform → S3 Bucket → Website User)؟
