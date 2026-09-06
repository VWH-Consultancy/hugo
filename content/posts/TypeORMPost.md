---
title: "Creating a TypeORM + TypeScript + PostgreSQL + Docker Demo"
date: 2026-09-02
draft: false
tags: [""]
summary: "In this post, we will walk through creating a TypeORM + TypeScript + PostgreSQL + Docker Demo."
---

Every app that has to remember anything ends up talking to a database, and no one wants to write raw SQL strings for every query. ORMs exist to bridge that gap: they map tables to classes and rows to objects, so your code works in types instead of `SELECT` statements. You see them in web apps, APIs, and internal tools, anywhere structured data is read and written. TypeORM is one of these, and pairing it with TypeScript hands the whole data layer to developers who already think in types. Same language on both ends, with the compiler catching your mistakes before the database does.

This post walks through creating a TypeORM + TypeScript + PostgreSQL + Docker Project.

A complete working example of the finished project is also available on GitHub. It demonstrates a fully functioning implementation of the concepts covered in this post and can be used as a reference alongside the tutorial.

**Example Project:** https://github.com/myzticx/TypeormPostgresDemo

---

## 1. What you will build

By the end of this post, your application will work like this:

```text
TypeScript application
        |
        v
      TypeORM
        |
        v
   PostgreSQL
        |
        v
      Docker
```

The application will create a `user` table and demonstrate full CRUD operations.

CRUD means:

- **C**reate → INSERT
- **R**ead → SELECT / QUERY
- **U**pdate → UPDATE
- **D**elete → DELETE

---

# 2. Prerequisites

Before starting, install:

- Node.js
- npm
- Docker Desktop
- VS Code (recommended)

You can check whether Node.js and npm are installed by opening a terminal and running:

```bash
node --version
```

Then:

```bash
npm --version
```

Check Docker:

```bash
docker --version
```

Make sure Docker Desktop is running before starting the database.

---

# 3. Create the project

Open a terminal.

Create the project directory:

```bash
mkdir typeorm-postgres-demo
```

Move into the directory:

```bash
cd typeorm-postgres-demo
```

Initialise the Node.js project:

```bash
npm init -y
```

You should now have:

```text
typeorm-postgres-demo/
└── package.json
```

---

# 4. Install TypeORM and PostgreSQL dependencies

Install the main dependencies:

```bash
npm install typeorm pg reflect-metadata dotenv
```

These packages are used for:

| Package            | Purpose                                 |
| ------------------ | --------------------------------------- |
| `typeorm`          | ORM used to communicate with PostgreSQL |
| `pg`               | PostgreSQL driver for Node.js           |
| `reflect-metadata` | Required by TypeORM decorators          |
| `dotenv`           | Loads variables from `.env`             |

Now install the development dependencies:

```bash
npm install -D typescript@5.9.3 ts-node@10.9.2 @types/node
```

The versions used in this demonstrated project are:

```text
TypeScript: 5.9.3
ts-node: 10.9.2
TypeORM: 1.1.0
```

You can check your installed versions:

```bash
npm list typescript ts-node typeorm
```

---

# 5. Create the TypeScript configuration

Generate a TypeScript configuration:

```bash
npx tsc --init
```

This creates:

```text
tsconfig.json
```

Open `tsconfig.json`.

Replace everything inside it with:

```json
{
  "compilerOptions": {
    "target": "ES2022",
    "module": "Node16",
    "moduleResolution": "Node16",
    "rootDir": "./src",
    "outDir": "./dist",
    "strict": true,
    "esModuleInterop": true,
    "experimentalDecorators": true,
    "emitDecoratorMetadata": true,
    "skipLibCheck": true,
    "types": ["node"]
  },
  "include": ["src/**/*"]
}
```

### Why are these settings needed?

`experimentalDecorators` and `emitDecoratorMetadata` allow TypeORM decorators such as:

```typescript
@Entity()
@Column()
@PrimaryGeneratedColumn()
```

to work correctly.

The following:

```json
"types": ["node"]
```

allows TypeScript to recognise Node.js features such as:

```typescript
process.env;
```

---

# 6. Create the source directories

From the project root, create the `src` directory:

```bash
mkdir src
```

Create the entities directory:

```bash
mkdir src/entities
```

Create the migrations directory:

```bash
mkdir src/migrations
```

Your project should now look like:

```text
typeorm-postgres-demo/
├── src/
│   ├── entities/
│   └── migrations/
├── package.json
├── package-lock.json
└── tsconfig.json
```

> If you are using Linux, WSL or Git Bash, you can alternatively use:
>
> ```bash
> mkdir -p src/entities src/migrations
> ```

---

# 7. Create PostgreSQL with Docker

Create a file in the project root called:

```text
docker-compose.yml
```

The file should be located here:

```text
typeorm-postgres-demo/docker-compose.yml
```

Add the following:

```yaml
services:
  postgres:
    image: postgres:17
    container_name: typeorm-postgres
    restart: unless-stopped

    environment:
      POSTGRES_USER: demo_user
      POSTGRES_PASSWORD: demo_password
      POSTGRES_DB: demo_db

    ports:
      - "5432:5432"

    volumes:
      - postgres_data:/var/lib/postgresql/data

volumes:
  postgres_data:
```

### What does this do?

Docker will download the PostgreSQL 17 image and create a PostgreSQL container.

The database details are:

```text
Database: demo_db
Username: demo_user
Password: demo_password
Host: localhost
Port: 5432
```

The Docker volume:

```text
postgres_data
```

stores the PostgreSQL data.

---

# 8. Start PostgreSQL

Make sure Docker Desktop is running.

From the project root, run:

```bash
docker compose up -d
```

The `-d` means Docker runs the container in the background.

Check the container:

```bash
docker ps
```

You should see a container called:

```text
typeorm-postgres
```

with a status similar to:

```text
Up ...
```

If you see the PostgreSQL container running, the database is ready.

---

# 9. Create the environment file

Create a file in the project root called:

```text
.env
```

Add:

```env
DB_HOST=localhost
DB_PORT=5432
DB_USERNAME=demo_user
DB_PASSWORD=demo_password
DB_DATABASE=demo_db
```

The project should now contain:

```text
typeorm-postgres-demo/
├── src/
├── .env
├── docker-compose.yml
├── package.json
├── package-lock.json
└── tsconfig.json
```

### Important

Do not commit `.env` to a public GitHub repository.

It contains database credentials.

---

# 10. Create the User entity

Create the following file:

```text
src/entities/User.ts
```

Add:

```typescript
import { Entity, PrimaryGeneratedColumn, Column } from "typeorm";

@Entity()
export class User {
  @PrimaryGeneratedColumn()
  id!: number;

  @Column()
  name!: string;

  @Column({ unique: true })
  email!: string;

  @Column()
  age!: number;
}
```

### What does this entity do?

It describes the structure of the database table.

The table will contain:

| Column  | Type    | Description                |
| ------- | ------- | -------------------------- |
| `id`    | integer | Automatically generated ID |
| `name`  | varchar | User's name                |
| `email` | varchar | User's unique email        |
| `age`   | integer | User's age                 |

Because we used:

```typescript
@Entity()
```

TypeORM will create a table named:

```text
user
```

The ID is automatically generated because of:

```typescript
@PrimaryGeneratedColumn()
```

The email is unique because of:

```typescript
@Column({ unique: true })
```

---

# 11. Create the TypeORM DataSource

Create:

```text
src/data-source.ts
```

Add:

```typescript
import "reflect-metadata";
import "dotenv/config";

import { DataSource } from "typeorm";
import { User } from "./entities/User";

export const AppDataSource = new DataSource({
  type: "postgres",

  host: process.env.DB_HOST,
  port: Number(process.env.DB_PORT),

  username: process.env.DB_USERNAME,
  password: process.env.DB_PASSWORD,

  database: process.env.DB_DATABASE,

  entities: [User],

  migrations: ["src/migrations/*.{ts,js}"],

  synchronize: false,
});
```

### What is the DataSource?

The `DataSource` tells TypeORM how to connect to PostgreSQL.

It gets the database settings from `.env`.

For example:

```typescript
host: process.env.DB_HOST;
```

gets:

```text
localhost
```

from:

```env
DB_HOST=localhost
```

---

# 12. Why is `synchronize` false?

The DataSource contains:

```typescript
synchronize: false;
```

This is intentional.

Instead of allowing TypeORM to automatically modify the database structure, this project uses **migrations**.

Migrations provide a controlled way to change the database schema.

For example:

```text
User entity
     ↓
Generate migration
     ↓
Run migration
     ↓
PostgreSQL table created
```

---

# 13. Add the npm scripts

Open:

```text
package.json
```

Find:

```json
"scripts": {
}
```

Change it to:

```json
"scripts": {
  "dev": "ts-node src/index.ts",
  "typeorm": "typeorm-ts-node-commonjs"
}
```

The `dev` command will run:

```text
src/index.ts
```

using `ts-node`.

---

# 14. Test TypeScript

Create:

```text
src/index.ts
```

For the first test, add:

```typescript
console.log("TypeORM PostgreSQL demo");
```

Run:

```bash
npm run dev
```

You should see:

```text
TypeORM PostgreSQL demo
```

This confirms that TypeScript and `ts-node` are working.

---

# 15. Test the PostgreSQL connection

Replace `src/index.ts` with:

```typescript
import { AppDataSource } from "./data-source";

async function main() {
  try {
    await AppDataSource.initialize();

    console.log("Successfully connected to PostgreSQL!");

    await AppDataSource.destroy();
  } catch (error) {
    console.error("Database connection failed:", error);
  }
}

main();
```

Run:

```bash
npm run dev
```

A successful connection should display:

```text
Successfully connected to PostgreSQL!
```

At this stage:

```text
TypeScript
    ↓
TypeORM
    ↓
PostgreSQL
    ↓
Docker
```

is working.

---

# 16. Generate the migration

The `User` entity defines what the table should look like.

However, PostgreSQL does not have the table yet.

Generate a migration from the project root:

```bash
npx typeorm-ts-node-commonjs migration:generate src/migrations/CreateUsers -d src/data-source.ts
```

You should receive a message similar to:

```text
Migration /.../src/migrations/xxxxxxxxxxxx-CreateUsers.ts has been generated successfully.
```

The exact number will be different for each project.

A migration file will appear in:

```text
src/migrations/
```

For example:

```text
src/migrations/
└── 1786545338366-CreateUsers.ts
```

Do not manually change the timestamp.

---

# 17. Run the migration

Run:

```bash
npx typeorm-ts-node-commonjs migration:run -d src/data-source.ts
```

TypeORM will connect to PostgreSQL and execute the migration.

You should see output similar to:

```text
CREATE TABLE "user" (...)
```

and:

```text
Migration CreateUsers... has been executed successfully.
```

TypeORM also creates a table called:

```text
migrations
```

This table keeps track of migrations that have already been executed.

---

# 18. Check the migration status

Run:

```bash
npx typeorm-ts-node-commonjs migration:show -d src/data-source.ts
```

The migration should be shown as executed.

It should have:

```text
[X]
```

next to it.

This confirms that the migration has been successfully applied.

---

# 19. Create the final CRUD application

Now replace the contents of:

```text
src/index.ts
```

with the following complete application:

```typescript
import { AppDataSource } from "./data-source";
import { User } from "./entities/User";

async function insertUser(): Promise<User> {
  const userRepository = AppDataSource.getRepository(User);

  const user = userRepository.create({
    name: "Jane Smith",
    email: `jane-${Date.now()}@example.com`,
    age: 20,
  });

  const savedUser = await userRepository.save(user);

  console.log("\n--- INSERT ---");
  console.log("User inserted:", savedUser);

  return savedUser;
}

async function getUsers(): Promise<User[]> {
  const userRepository = AppDataSource.getRepository(User);

  const users = await userRepository.find();

  console.log("\n--- QUERY ---");
  console.table(users);

  return users;
}

async function updateUser(userId: number): Promise<User> {
  const userRepository = AppDataSource.getRepository(User);

  const user = await userRepository.findOneBy({
    id: userId,
  });

  if (!user) {
    throw new Error(`User with ID ${userId} not found`);
  }

  user.name = "Jane Updated";
  user.age = 21;

  const updatedUser = await userRepository.save(user);

  console.log("\n--- UPDATE ---");
  console.log("User updated:", updatedUser);

  return updatedUser;
}

async function deleteUser(userId: number): Promise<void> {
  const userRepository = AppDataSource.getRepository(User);

  const user = await userRepository.findOneBy({
    id: userId,
  });

  if (!user) {
    console.log(`User with ID ${userId} not found`);
    return;
  }

  await userRepository.remove(user);

  console.log("\n--- DELETE ---");
  console.log(`User ${userId} deleted`);
}

async function main() {
  try {
    await AppDataSource.initialize();

    console.log("Connected to PostgreSQL!");

    // INSERT
    const user = await insertUser();

    // QUERY
    await getUsers();

    // UPDATE
    await updateUser(user.id);

    // QUERY again to prove the update
    await getUsers();

    // DELETE
    await deleteUser(user.id);

    // Final QUERY to prove deletion
    await getUsers();
  } catch (error) {
    console.error("Error:", error);
  } finally {
    if (AppDataSource.isInitialized) {
      await AppDataSource.destroy();
    }
  }
}

main();
```

---

# 20. Run the completed application

First make sure PostgreSQL is running:

```bash
docker compose up -d
```

Then run the application:

```bash
npm run dev
```

You should get output similar to:

```text
Connected to PostgreSQL!

--- INSERT ---
User inserted: User {
  id: 1,
  name: 'Jane Smith',
  email: 'jane-xxxxxxxx@example.com',
  age: 20
}

--- QUERY ---
┌─────────┬────┬──────────────┬─────────────────────────────┬─────┐
│ (index) │ id │ name         │ email                       │ age │
├─────────┼────┼──────────────┼─────────────────────────────┼─────┤
│ 0       │ 1  │ 'Jane Smith' │ 'jane-xxxxxxxx@example.com' │ 20  │
└─────────┴────┴──────────────┴─────────────────────────────┴─────┘

--- UPDATE ---
User updated: User {
  id: 1,
  name: 'Jane Updated',
  email: 'jane-xxxxxxxx@example.com',
  age: 21
}

--- QUERY ---
...

--- DELETE ---
User 1 deleted

--- QUERY ---
...
```

The exact IDs and email values can be different.

---

# 21. Why does the email contain a timestamp?

The INSERT uses:

```typescript
email: `jane-${Date.now()}@example.com`;
```

`Date.now()` creates a different number each time the program runs.

For example:

```text
jane-1755000000000@example.com
```

This prevents the demo from repeatedly trying to insert the same email address.

This is necessary because the entity contains:

```typescript
@Column({ unique: true })
email!: string;
```

---

# 22. How INSERT works

The application creates a new user:

```typescript
const user = userRepository.create({
  name: "Jane Smith",
  email: `jane-${Date.now()}@example.com`,
  age: 20,
});
```

Then saves it:

```typescript
const savedUser = await userRepository.save(user);
```

TypeORM performs an operation equivalent to:

```sql
INSERT INTO "user" ("name", "email", "age")
VALUES (...);
```

This is the **Create** part of CRUD.

---

# 23. How QUERY / SELECT works

The application retrieves all users:

```typescript
const users = await userRepository.find();
```

TypeORM performs an operation equivalent to:

```sql
SELECT * FROM "user";
```

The results are displayed using:

```typescript
console.table(users);
```

This is the **Read** part of CRUD.

---

# 24. How UPDATE works

First, the user is found:

```typescript
const user = await userRepository.findOneBy({
  id: userId,
});
```

Then the properties are changed:

```typescript
user.name = "Jane Updated";
user.age = 21;
```

The updated user is saved:

```typescript
const updatedUser = await userRepository.save(user);
```

This is equivalent to an SQL operation similar to:

```sql
UPDATE "user"
SET "name" = 'Jane Updated',
    "age" = 21
WHERE "id" = ...;
```

This is the **Update** part of CRUD.

---

# 25. How DELETE works

First, the user is found:

```typescript
const user = await userRepository.findOneBy({
  id: userId,
});
```

Then it is removed:

```typescript
await userRepository.remove(user);
```

This is equivalent to:

```sql
DELETE FROM "user"
WHERE "id" = ...;
```

This is the **Delete** part of CRUD.

---

# 26. Final project structure

The completed project should look like:

```text
typeorm-postgres-demo/
│
├── src/
│   ├── entities/
│   │   └── User.ts
│   │
│   ├── migrations/
│   │   └── 1786545338366-CreateUsers.ts
│   │
│   ├── data-source.ts
│   └── index.ts
│
├── .env
├── docker-compose.yml
├── package.json
├── package-lock.json
├── tsconfig.json
└── node_modules/
```

The migration timestamp will be different when generated on another machine.

---

# 27. Create a `.gitignore`

If the project is going to be uploaded to GitHub, create:

```text
.gitignore
```

Add:

```gitignore
node_modules/
dist/
.env
```

This prevents:

- `node_modules` from being uploaded
- compiled files from being uploaded
- database credentials from being uploaded

---

# 28. Complete demonstration procedure

When demonstrating the finished project, follow these steps.

## Step 1 — Start Docker

```bash
docker compose up -d
```

## Step 2 — Check the container

```bash
docker ps
```

Make sure `typeorm-postgres` is running.

## Step 3 — Check migrations

```bash
npx typeorm-ts-node-commonjs migration:show -d src/data-source.ts
```

The migration should show:

```text
[X]
```

## Step 4 — Run the application

```bash
npm run dev
```

## Step 5 — Explain the output

The application demonstrates:

### Connection

```text
Connected to PostgreSQL!
```

This proves TypeORM successfully connected to PostgreSQL.

### INSERT

```text
--- INSERT ---
```

A new user is created.

### QUERY

```text
--- QUERY ---
```

The users currently stored in the database are retrieved.

### UPDATE

```text
--- UPDATE ---
```

The newly inserted user is updated.

### QUERY

The database is queried again to prove the update was saved.

### DELETE

```text
--- DELETE ---
```

The user is removed from the database.

### Final QUERY

The database is queried one final time to prove that the deleted user is no longer present.

---

# 29. Troubleshooting

## Error: `Cannot find name 'process'`

Install Node.js type definitions:

```bash
npm install -D @types/node
```

Then make sure `tsconfig.json` contains:

```json
"types": ["node"]
```

---

## Error: `Cannot find module './index.ts'`

Make sure this file exists:

```text
src/index.ts
```

Also make sure you are running the command from the project root:

```text
typeorm-postgres-demo/
```

Run:

```bash
npm run dev
```

Do not run it from:

```text
src/
```

---

## Error: TypeScript / ts-node configuration problems

Use the demonstrated versions:

```bash
npm install -D typescript@5.9.3 ts-node@10.9.2
```

Then check:

```bash
npm list typescript ts-node
```

---

## Error: PostgreSQL connection refused

Check whether Docker is running:

```bash
docker ps
```

If the PostgreSQL container is missing, start it:

```bash
docker compose up -d
```

Check the `.env` file:

```env
DB_HOST=localhost
DB_PORT=5432
DB_USERNAME=demo_user
DB_PASSWORD=demo_password
DB_DATABASE=demo_db
```

---

## Error: `Missing required argument: dataSource`

Run the migration using:

```bash
npx typeorm-ts-node-commonjs migration:run -d src/data-source.ts
```

The `-d` option tells TypeORM where the DataSource is located.

---

# 30. Useful Docker commands

Start PostgreSQL:

```bash
docker compose up -d
```

Stop PostgreSQL:

```bash
docker compose down
```

View running containers:

```bash
docker ps
```

View PostgreSQL logs:

```bash
docker compose logs postgres
```

Restart the PostgreSQL service:

```bash
docker compose restart postgres
```

---

# 31. Useful TypeORM migration commands

Generate a migration:

```bash
npx typeorm-ts-node-commonjs migration:generate src/migrations/CreateUsers -d src/data-source.ts
```

Run pending migrations:

```bash
npx typeorm-ts-node-commonjs migration:run -d src/data-source.ts
```

Show migration status:

```bash
npx typeorm-ts-node-commonjs migration:show -d src/data-source.ts
```

Revert the most recent migration:

```bash
npx typeorm-ts-node-commonjs migration:revert -d src/data-source.ts
```

> Only use `migration:revert` when you intentionally want to undo the latest migration.

---

# 32. Final checklist

Before considering the project complete, verify each item:

- [ ] Node.js is installed
- [ ] npm is installed
- [ ] Docker is installed
- [ ] Docker PostgreSQL container is running
- [ ] `package.json` exists
- [ ] `tsconfig.json` is configured
- [ ] `.env` exists
- [ ] `docker-compose.yml` exists
- [ ] `src/entities/User.ts` exists
- [ ] `src/data-source.ts` exists
- [ ] `src/migrations/` contains the generated migration
- [ ] The migration has been executed
- [ ] `src/index.ts` contains the CRUD demo
- [ ] `npm run dev` connects successfully
- [ ] INSERT works
- [ ] QUERY works
- [ ] UPDATE works
- [ ] DELETE works

---

# 33. Final result

The completed project demonstrates a full database workflow using:

```text
TypeScript
   +
TypeORM
   +
PostgreSQL
   +
Docker
```

The application can:

```text
Connect to PostgreSQL
        ↓
Run migrations
        ↓
INSERT users
        ↓
QUERY users
        ↓
UPDATE users
        ↓
QUERY users again
        ↓
DELETE users
        ↓
QUERY again
```

After completing this you will have successfully created a TypeORM with TypeScript and a PostgreSQL SQL service running through Docker, including migrations, queries, updates and insertions.
