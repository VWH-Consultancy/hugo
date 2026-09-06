---
title: "Creating a Node.js S3 CRUD Application using RustFS and Docker"
date: 2026-07-20
draft: false
tags: [""]
summary: "In this post, we will walk through creating a Node.js application that performs S3 CRUD operations using RustFS running locally with Docker."
---

Every business that moves data around eventually needs somewhere to put it, and ETL almost always lands in the same place: object storage, because the S3 API won. This post builds the smallest version of that skill. You'll run RustFS, a local S3-compatible object store, in Docker and wire a Node.js client to it with the AWS SDK, then create, read, update, and delete objects. No AWS account required.

This post walks through creating a Node.js application that communicates with a local S3-compatible storage service using RustFS.

RustFS provides an S3-compatible API that allows applications to store, read, update and delete objects using the same concepts as Amazon S3.

The finished project will demonstrate:

- Running RustFS locally using Docker.
- Creating an S3-compatible bucket.
- Connecting Node.js to RustFS using the AWS S3 SDK.
- Separating the application into client, CRUD and application files.
- Performing Create, Read, Update and Delete operations.

Everything in this post runs locally and does not require an AWS account.

**Example Project:** https://github.com/myzticx/RustFsNodeDemo

---

# Prerequisites

Before starting, please ensure you have the following installed:

- Node.js
- npm
- Docker Desktop
- Visual Studio Code

Verify Node.js is installed:

```bash
node --version
```

Verify Docker is installed:

```bash
docker --version
```

Verify Docker is running:

```bash
docker ps
```

---

# Step 1 - Creating the RustFS Docker Environment

RustFS will be used as a local S3-compatible storage service.

Create a new folder:

```bash
mkdir rustfs
```

Navigate into the folder:

```bash
cd rustfs
```

The folder will contain the Docker configuration:

```text
rustfs/
└── docker-compose.yml
```

---

# Step 2 - Creating the Docker Compose Configuration

Inside the `rustfs` folder create:

```text
docker-compose.yml
```

macOS/Linux:

```bash
touch docker-compose.yml
```

Windows PowerShell:

```powershell
New-Item docker-compose.yml
```

Add the following configuration:

```yaml
services:
  rustfs:
    image: rustfs/rustfs:latest
    container_name: rustfs

    ports:
      - "9000:9000"
      - "9001:9001"

    environment:
      RUSTFS_ACCESS_KEY: admin
      RUSTFS_SECRET_KEY: password123

    volumes:
      - rustfs-data:/data

    command: server /data --console-address ":9001"

volumes:
  rustfs-data:
```

This configuration:

- Downloads the RustFS Docker image.
- Creates a RustFS container.
- Exposes the S3 API on port `9000`.
- Exposes the web console on port `9001`.
- Creates persistent storage using a Docker volume.

---

# Step 3 - Starting RustFS

From inside the `rustfs` folder run:

```bash
docker compose up -d
```

Docker will download and start RustFS.

Check that the container is running:

```bash
docker ps
```

Expected output:

```text
PORTS

0.0.0.0:9000->9000/tcp
0.0.0.0:9001->9001/tcp
```

RustFS is now running.

---

# Step 4 - Accessing the RustFS Console

Open your browser:

```
http://localhost:9001
```

Login using the access key credentials:

```
Account: admin
Key: password123
```

These credentials were created in the Docker Compose file.

The S3 connection details are:

```
Endpoint:
http://localhost:9000

Access Key:
admin

Secret Key:
password123
```

---

# Step 5 - Creating an S3 Bucket

Inside the RustFS console:

1. Navigate to **Buckets**.
2. Select **Create Bucket**.
3. Create a bucket called:

```
my-bucket
```

The final S3 configuration is:

| Setting    | Value                 |
| ---------- | --------------------- |
| Endpoint   | http://localhost:9000 |
| Access Key | admin                 |
| Secret Key | password123           |
| Bucket     | my-bucket             |

---

# Step 6 - Creating the Node.js Project

Open a new terminal.

Create the project:

```bash
mkdir rustfs-node-demo
```

Navigate into it:

```bash
cd rustfs-node-demo
```

The project will contain the Node.js application.

---

# Step 7 - Initialising the Node Project

Initialise npm:

```bash
npm init -y
```

This creates:

```text
package.json
```

---

# Step 8 - Installing the S3 SDK

Install the AWS S3 SDK:

```bash
npm install @aws-sdk/client-s3
```

The project now contains:

```text
rustfs-node-demo/

├── node_modules/
├── package.json
└── package-lock.json
```

---

# Step 9 - Creating the Application Files

Create the following files:

```text
rustfs-node-demo/

├── app.js
├── crud.js
└── s3Client.js
```

macOS/Linux:

```bash
touch app.js crud.js s3Client.js
```

Windows PowerShell:

```powershell
New-Item app.js
New-Item crud.js
New-Item s3Client.js
```

Open the project:

```bash
code .
```

---

# Step 10 - Creating the S3 Client

The `s3Client.js` file is responsible for creating the connection between Node.js and RustFS.

Open:

```text
s3Client.js
```

Add:

```javascript
const { S3Client } = require("@aws-sdk/client-s3");

const client = new S3Client({
  endpoint: "http://localhost:9000",

  region: "us-east-1",

  credentials: {
    accessKeyId: "admin",
    secretAccessKey: "password123",
  },

  forcePathStyle: true,
});

module.exports = client;
```

The `forcePathStyle` option is required because RustFS runs locally instead of using AWS S3 domain-based URLs.

---

# Step 11 - Creating the CRUD Files

The application will now be separated into three files:

```text
rustfs-node-demo/

├── app.js          # Runs commands from the terminal
├── crud.js         # Contains CRUD operations
└── s3Client.js     # Handles the RustFS connection
```

The separation keeps the project organised:

- `s3Client.js` manages the connection to RustFS.
- `crud.js` contains the S3 operations.
- `app.js` allows users to run commands from the terminal.

---

# Step 12 - Implementing the CRUD Operations

The `crud.js` file contains all Create, Read, Update and Delete operations.

Open:

```text
crud.js
```

Add the following:

```javascript
const {
  PutObjectCommand,
  GetObjectCommand,
  DeleteObjectCommand,
  ListObjectsV2Command,
} = require("@aws-sdk/client-s3");

const client = require("./s3Client");

const bucket = "my-bucket";

// CREATE - Upload an object
async function upload() {
  try {
    await client.send(
      new PutObjectCommand({
        Bucket: bucket,
        Key: "hello.txt",
        Body: "Hello from RustFS!",
      }),
    );

    console.log("✅ Upload complete");
  } catch (err) {
    console.error(err);
  }
}

// READ - Retrieve an object
async function read() {
  try {
    const response = await client.send(
      new GetObjectCommand({
        Bucket: bucket,
        Key: "hello.txt",
      }),
    );

    const text = await response.Body.transformToString();

    console.log(text);
  } catch (err) {
    console.error(err);
  }
}

// UPDATE - Replace object contents
async function update() {
  try {
    await client.send(
      new PutObjectCommand({
        Bucket: bucket,
        Key: "hello.txt",
        Body: "Updated from Node.js!",
      }),
    );

    console.log("✅ Updated");
  } catch (err) {
    console.error(err);
  }
}

// DELETE - Remove an object
async function remove() {
  try {
    await client.send(
      new DeleteObjectCommand({
        Bucket: bucket,
        Key: "hello.txt",
      }),
    );

    console.log("✅ Deleted");
  } catch (err) {
    console.error(err);
  }
}

// LIST - Display bucket contents
async function list() {
  try {
    const response = await client.send(
      new ListObjectsV2Command({
        Bucket: bucket,
      }),
    );

    console.log(response.Contents);
  } catch (err) {
    console.error(err);
  }
}

module.exports = {
  upload,
  read,
  update,
  remove,
  list,
};
```

This file provides the following functionality:

| Operation | Function   | Description                        |
| --------- | ---------- | ---------------------------------- |
| Create    | `upload()` | Creates a new object inside RustFS |
| Read      | `read()`   | Retrieves an object from RustFS    |
| Update    | `update()` | Replaces an object's contents      |
| Delete    | `remove()` | Deletes an object                  |
| List      | `list()`   | Displays bucket contents           |

---

# Step 13 - Creating the Application Runner

The `app.js` file allows CRUD operations to be executed from the terminal.

The application runner imports the CRUD functions from `crud.js` and selects which operation to run based on the command entered.

Open:

```text
app.js
```

Add:

```javascript
const { upload, read, update, remove, list } = require("./crud");

const action = process.argv[2];

switch (action) {
  case "upload":
    upload();
    break;

  case "read":
    read();
    break;

  case "update":
    update();
    break;

  case "delete":
    remove();
    break;

  case "list":
    list();
    break;

  default:
    console.log("Usage:");
    console.log("node app.js upload");
    console.log("node app.js read");
    console.log("node app.js update");
    console.log("node app.js delete");
    console.log("node app.js list");
}
```

The application accepts the following terminal commands:

```bash
node app.js upload
```

Creates a new object inside the RustFS bucket.

```bash
node app.js read
```

Reads an existing object from the RustFS bucket.

```bash
node app.js update
```

Updates the contents of an existing object.

```bash
node app.js delete
```

Deletes an object from the bucket.

```bash
node app.js list
```

Lists all objects stored inside the bucket.

Each command calls the matching function from `crud.js`.

---

# Step 14 - Running the CRUD Application

Before running any commands, make sure RustFS is running.

Open a terminal window.

Navigate to the RustFS folder:

```bash
cd rustfs
```

Start RustFS:

```bash
docker compose up -d
```

Verify RustFS is running:

```bash
docker ps
```

You should see the RustFS container running:

```text
rustfs
```

---

Open a second terminal window.

Navigate to the Node.js project:

```bash
cd rustfs-node-demo
```

All CRUD commands should be executed from this folder.

---

# Creating / Uploading an Object

To create a new object inside the RustFS bucket run:

```bash
node app.js upload
```

Expected output:

```text
✅ Upload complete
```

This creates:

```text
hello.txt
```

inside:

```text
my-bucket
```

---

# Reading an Object

To retrieve an object from RustFS run:

```bash
node app.js read
```

The application will:

1. Connect to RustFS.
2. Find `hello.txt`.
3. Download the contents.
4. Display the contents in the terminal.

Example output:

```text
Hello from RustFS!
```

---

# Updating an Object

To update an existing object run:

```bash
node app.js update
```

Expected output:

```text
✅ Updated
```

The contents of:

```text
hello.txt
```

are replaced.

To confirm the update:

```bash
node app.js read
```

Example output:

```text
Updated from Node.js!
```

---

# Deleting an Object

To delete an object from the bucket run:

```bash
node app.js delete
```

Expected output:

```text
✅ Deleted
```

The object is removed from:

```text
my-bucket
```

---

# Listing Bucket Contents

To display all objects stored inside the bucket:

```bash
node app.js list
```

Example output:

```text
[
  {
    Key: 'hello.txt',
    LastModified: 2026-09-06T18:35:15.937Z,
    ETag: '"82116f73981dd06d9bfcac4bc2005d28"',
    Size: 21,
    StorageClass: 'STANDARD'
  }
]
```

The exact `LastModified`, `ETag` and `Size` values will differ. If the bucket is empty, `list` prints `undefined` because `response.Contents` does not exist.

---

# Step 15 - Complete Project Structure

After completing the post, the final project structure should look like:

```text
rustfs-node-demo/

│
├── node_modules/
│
├── package.json
├── package-lock.json
│
├── app.js
├── crud.js
└── s3Client.js
```

> The example project at https://github.com/myzticx/RustFsNodeDemo keeps `docker-compose.yml` and the Node.js files together in a single folder. This post separates them into `rustfs/` and `rustfs-node-demo/` for clarity; either layout works.

---

# How The Application Works

The request flow is:

```text
Terminal Command

node app.js upload

        |
        v

      app.js

        |
        v

      crud.js

        |
        v

   s3Client.js

        |
        v

 RustFS Docker Container

        |
        v

    S3 Bucket
```

---

# File Responsibilities

## app.js

Responsible for:

- Reading terminal commands.
- Selecting the requested CRUD operation.
- Calling the correct function.

---

## crud.js

Responsible for:

- Creating objects.
- Reading objects.
- Updating objects.
- Deleting objects.
- Listing objects.

---

## s3Client.js

Responsible for:

- Connecting Node.js to RustFS.
- Providing authentication credentials.
- Configuring the S3 client.

---

# Troubleshooting

## RustFS Connection Error

Example:

```text
ECONNREFUSED 127.0.0.1:9000
```

Cause:

RustFS is not running.

Fix:

```bash
cd rustfs

docker compose up -d
```

---

## Bucket Not Found

Example:

```text
NoSuchBucket
```

Cause:

The bucket does not exist.

Fix:

Open:

```
http://localhost:9001
```

Create:

```
my-bucket
```

---

## Authentication Error

Example:

```text
AccessDenied
```

Cause:

The credentials in `s3Client.js` do not match RustFS.

Verify:

```
Access Key:
admin

Secret Key:
password123
```

---

# Expected Outcome

After completing this post you will have:

- RustFS running locally using Docker.
- A Node.js application connected using the AWS S3 SDK.
- A separated S3 client and CRUD structure.
- A local S3-compatible storage system.
- The ability to create, read, update and delete objects using terminal commands.

---
