---
title: "Creating a TypeScript Node.js server and securing it using Docker, Keycloak and Client Credentials"
date: 2026-07-06
draft: false
tags: [""]
summary: "In this guide, we will walk through creating a TypeScript Node.js server and securing it using Docker, Keycloak and Client Credentials."
---

This guide walks through building and securing a TypeScript Node.js Express API using Docker, Keycloak and the OAuth 2.0 Client Credentials flow.

A complete working example of the finished project is also available on GitHub. It demonstrates a fully functioning implementation of the concepts covered in this guide and can be used as a reference alongside the tutorial.

**Example Project:** https://github.com/myzticx/TestSecuredNodeServerTS

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

Initialise npm

```bash
npm init -y
```

Install the required runtime dependencies

```bash
npm install express dotenv jose
```

Install TypeScript together with the required type definitions

```bash
npm install -D typescript ts-node @types/node @types/express
```

Initialise TypeScript

```bash
npx tsc --init
```

Replace the generated `tsconfig.json` with the following configuration

```json
{
  "compilerOptions": {
    "target": "ES2022",
    "module": "CommonJS",
    "moduleResolution": "node",
    "rootDir": "./src",
    "outDir": "./dist",
    "strict": true,
    "esModuleInterop": true,
    "skipLibCheck": true
  }
}
```

Before moving onto the next step, your folder structure should look similar to this

```text
api/
├── node_modules/
├── package.json
├── package-lock.json
├── tsconfig.json
```

---

# Step 3 - Creating the Express Application

Inside the **api** folder create:

```text
src/
├── index.ts
└── auth.ts

.env
.env.example
```

### src/index.ts

```typescript
import dotenv from "dotenv";
dotenv.config();

import express from "express";
import authenticate from "./auth";

const app = express();

app.get("/", (_req, res) => {
  res.send("API running");
});

app.get("/api/hello", authenticate, (req, res) => {
  res.json({
    message: "Hello from the protected API",
    tokenInfo: (req as any).user,
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

Start Keycloak by running

```bash
docker compose up
```

---

# Step 5 - Create a Realm

Open your browser and navigate to

```
http://localhost:8080
```

Log in using the default administrator credentials

```
Username: admin
Password: admin
```

Keycloak already contains a default realm called **master**.

Leave this untouched.

Create a new realm called

```
demo
```

Click **Create**.

---

# Step 6 - Create a Client

Switch to the **demo** realm that you just created.

Navigate to

```
Clients
```

Create a new client.

Client ID

```
node-api-client
```

Enable the following options

- Client Authentication
- Service Accounts Roles

Disable every other authentication flow.

Click **Save**.

---

# Step 7 - Copy the Client Secret

Navigate to

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

Using Postman, create a new **POST** request.

Request URL

```
http://localhost:8080/realms/demo/protocol/openid-connect/token
```

Body type

```
x-www-form-urlencoded
```

Add the following fields

| Key           | Value              |
| ------------- | ------------------ |
| grant_type    | client_credentials |
| client_id     | node-api-client    |
| client_secret | YOUR_CLIENT_SECRET |

Click **Send**.

A successful response returns

```json
{
  "access_token": "eyJ..."
}
```

This is your Access Token.

---

# Step 9 - Create the Authentication Middleware

Navigate to the file that you created earlier called **src/auth.ts**

```typescript
import { Request, Response, NextFunction } from "express";
import { createRemoteJWKSet, jwtVerify } from "jose";

const issuer = process.env.KEYCLOAK_ISSUER;

if (!issuer) {
  throw new Error("KEYCLOAK_ISSUER is not defined in .env");
}

const JWKS = createRemoteJWKSet(
  new URL(`${issuer}/protocol/openid-connect/certs`),
);

export default async function authenticate(
  req: Request,
  res: Response,
  next: NextFunction,
) {
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

    (req as any).user = payload;

    next();
  } catch (err) {
    return res.status(401).json({
      error: "Invalid token",
    });
  }
}
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
npm run dev
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
401 Unauthorized
```

---

With a valid access token:

In Postman select:

```
Authorization → Bearer Token
```

Paste only the value of the `access_token` returned by Keycloak.

Send:

```
GET http://localhost:3000/api/hello
```

Expected response:

```json
{
  "message": "Hello from the protected API",
  "tokenInfo": {
    ...
  }
}
```

---

# Project Structure

Final TypeScript project structure:

```text
secure-node-api-keycloak/
│
├── docker-compose.yml
│
├── api/
│   ├── src/
│   │   ├── auth.ts
│   │   └── index.ts
│   │
│   │
│   ├── .env
│   ├── .env.example
│   ├── package.json
│   ├── package-lock.json
│   ├── tsconfig.json
│   └── node_modules/
│
├── keycloak/
│
└── README.md
```

---

# Authentication Flow

The authentication process follows these steps:

1. The client authenticates with Keycloak using its Client ID and Client Secret.
2. Keycloak validates the credentials.
3. A JWT access token is issued.
4. The client includes the JWT in the Authorization header.
5. The Express middleware verifies the JWT using Keycloak's public keys.
6. If valid, the protected endpoint is accessed.
7. If invalid or missing, the API returns **401 Unauthorized**.

---

# Expected Outcome

After completing this guide you will have:

- A **TypeScript** Node.js Express API.
- A Keycloak server running in Docker.
- A **demo** realm.
- A confidential client called **node-api-client**.
- JWT authentication using the OAuth 2.0 Client Credentials flow.
- A protected API endpoint that only accepts valid Bearer tokens.
- Automatic rejection of unauthorised requests with **401 Unauthorized**.
