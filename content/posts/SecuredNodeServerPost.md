---
title: "Creating a Node.js server and securing it using Docker, Keycloak and Client Credentials"
date: 2026-07-01
draft: false
tags: [""]
summary: "In this guide, we will walk through creating a Node.js server and securing it using Docker, Keycloak and Client Credentials."
---

I’ve been burned enough times by hosted auth providers that wanted per-seat pricing before I’d even shipped, so I started looking for a self-hosted solution that wouldn’t lock me into opaque pricing. After implementing OIDC across several projects, each with different libraries and quirks, I landed on Keycloak. It’s battle tested, it’s free, and it gives you a real playground to understand the guts of OAuth without reaching for a credit card. If you’re building an internal API that needs machine-to-machine authentication (the classic Client Credentials flow), Keycloak gets out of your way once it’s set up.

Here’s the exact path I followed to spin up a Node.js Express API, lock it down with JWT validation, and let Keycloak handle the token issuance, all running in Docker.

A complete working example of the finished project is also available on GitHub. It demonstrates a fully functioning implementation of the concepts covered in this guide and can be used as a reference alongside the tutorial.

**Example Project:** https://github.com/VWH-Consultancy/TestSecuredNodeServer

---

# Prerequisites

Before starting, please ensure you have the following installed:

- Node.js
- npm
- Docker Desktop
- Postman
- Visual Studio Code

---

# Step 1 - Creating the Project

To get started, create the following project structure

```text
<your-project-name>/
│
├── api/
├── keycloak/
└── README.md
```

---

# Step 2 - Initialising the Node Project

After creating the project, navigate into the API folder

```bash
cd api
```

Initalise npm

```bash
npm init -y
```

Then install the required dependencies

```bash
npm install express dotenv jose
```

Before moving onto the next step, your folder structure should look similar to this

```text
api/
├── node_modules/
├── package.json
├── package-lock.json
```

---

# Step 3 - Creating the Express Application

Inside the **api** folder create:

```text
index.js
auth.js
.env
.env.example
```

### index.js

```javascript
require("dotenv").config();

const express = require("express");
const authenticate = require("./auth");

const app = express();

app.get("/", (req, res) => {
  res.send("API running");
});

app.get("/api/hello", authenticate, (req, res) => {
  res.json({
    message: "Hello from the protected API",
    tokenInfo: req.user,
  });
});

const PORT = process.env.PORT || 3000;

app.listen(PORT, () => {
  console.log(`Listening on port ${PORT}`);
});
```

---

### .env

```env
PORT=3000
KEYCLOAK_ISSUER=http://localhost:8080/realms/demo
```

---

### .env.example

```env
PORT=3000
KEYCLOAK_ISSUER=http://localhost:8080/realms/demo
```

---

# Step 4 - Docker Compose

At the root of the project create:

```text
docker-compose.yml
```

Add the following to the file:

```yaml
services:
  keycloak:
    image: quay.io/keycloak/keycloak:26.2
    command: start-dev

    ports:
      - "8080:8080"

    environment:
      KEYCLOAK_ADMIN: admin
      KEYCLOAK_ADMIN_PASSWORD: admin
```

---

# Step 5 - Create a Realm

Keycloak already contains a default realm called **master**.

Leave this untouched.

Create a new realm called:

```
demo
```

Ensure **Enabled** remains switched on.

Click **Create**.

---

# Step 6 - Create a Client

Switch to the **demo** realm that you just created.

Navigate to:

```
Clients
```

Create a new client.

Client ID:

```
node-api-client
```

Click **Next**.

Enable:

- Client Authentication
- Service Accounts Roles

Disable every other authentication flow.

Click **Save**.

---

# Step 7 - Copy the Client Secret

Navigate to:

```
Clients
↓

node-api-client
↓

Credentials
```

Copy the **Client Secret**.

Keep this safe as it will be needed when requesting access tokens.

---

# Step 8 - Obtain an Access Token

Using Postman, create a new POST request.

Request URL:

```
http://localhost:8080/realms/demo/protocol/openid-connect/token
```

Body type:

```
x-www-form-urlencoded
```

Add the following fields:

| Key           | Value              |
| ------------- | ------------------ |
| grant_type    | client_credentials |
| client_id     | node-api-client    |
| client_secret | YOUR_CLIENT_SECRET |

Click **Send**.

A successful response returns:

```json
{
  "access_token": "eyJ..."
}
```

This is your Access Token.

---

# Step 9 - Create the Authentication Middleware

Navigate to the file that you created earlier called **auth.js**.

```javascript
require("dotenv").config();

const { createRemoteJWKSet, jwtVerify } = require("jose");

const issuer = process.env.KEYCLOAK_ISSUER;

const JWKS = createRemoteJWKSet(
  new URL(`${issuer}/protocol/openid-connect/certs`),
);

async function authenticate(req, res, next) {
  const authHeader = req.headers.authorization;

  if (!authHeader || !authHeader.startsWith("Bearer ")) {
    return res.status(401).json({
      error: "Missing Bearer token",
    });
  }

  const token = authHeader.split(" ")[1];

  try {
    const { payload } = await jwtVerify(token, JWKS, {
      issuer,
    });

    req.user = payload;

    next();
  } catch (err) {
    console.error(err);

    return res.status(401).json({
      error: "Invalid token",
    });
  }
}

module.exports = authenticate;
```

The middleware performs the following tasks:

- Reads the Bearer token from the request.
- Retrieves Keycloak's public signing keys.
- Verifies the JWT signature.
- Confirms the issuer is the **demo** realm that you created.
- Rejects invalid or expired tokens.

---

# Step 10 - Run the API

From inside the **api** directory run:

```bash
node index.js
```

Expected output:

```
Listening on port 3000
```

---

# Step 11 - Test the Public Endpoint

Request:

```
GET http://localhost:3000/
```

Response:

```
API running
```

---

# Step 12 - Test the Protected Endpoint

Without a token:

```
GET http://localhost:3000/api/hello
```

Response:

```json
{
  "error": "Missing Bearer token"
}
```

Status:

```
401 Unauthorised
```

---

With a valid access token:

In Postman select:

```
Authorization
↓

Bearer Token
```

Paste only the value of the **access_token** returned by Keycloak.

Do not include the word **Bearer**, as Postman automatically adds it.

Send:

```
GET http://localhost:3000/api/hello
```

Expected response:

```json
{
    "message":"Hello from the protected API",
    "tokenInfo":{
        ...
    }
}
```

---

# Authentication Flow

The authentication process follows these steps:

1. The client authenticates with Keycloak using its Client ID and Client Secret.
2. Keycloak validates the credentials.
3. A JWT access token is issued.
4. The client includes the JWT in the Authorisation header.
5. The Express middleware verifies the JWT using Keycloak's public keys.
6. If valid, the protected endpoint is accessed.
7. If invalid or missing, the API returns **401 Unauthorised**.

---

# Project Structure

```text
secure-node-api-keycloak/
│
├── docker-compose.yml
│
├── api/
│   ├── auth.js
│   ├── index.js
│   ├── .env
│   ├── .env.example
│   ├── package.json
│   ├── package-lock.json
│   └── node_modules/
│
├── keycloak/
│
└── README.md
```

---

# Expected Outcome

After completing this guide you will have:

- A Node.js Express API.
- A Keycloak server running in Docker.
- A **demo** realm.
- A confidential client called **node-api-client**.
- JWT authentication using the OAuth 2.0 Client Credentials flow.
- A protected API endpoint that only accepts valid Bearer tokens.
- Automatic rejection of unauthorised requests with **401 Unauthorised**.