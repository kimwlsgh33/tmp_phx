# PostgreSQL Cheat Sheet

## Connect to a Database

```bash
psql -U postgres -d <database_name>
```

## List All Databases

```bash
\l
```

## Drop a Database

```sql
DROP DATABASE database_name;
```

Where `database_name` is the name of the database you want to delete.

**Important considerations:**

* **Permissions:** You need to be a superuser or have the `DROPDATABASE` privilege for the target database to execute this command.
* **Connections:** If there are any active connections to the database you are trying to drop, the command will fail. You need to terminate all connections to the database first.

**Here's a more detailed explanation and examples:**

1. **Connect to PostgreSQL:** First, you need to connect to your PostgreSQL server using a tool like `psql` (the PostgreSQL command-line interface) or a GUI tool like pgAdmin. You'll usually connect to the `postgres` database or another system database.

2. **Identify the database:** Make sure you know the exact name of the database you want to drop. You can list existing databases using the `\l` command in `psql`.

3. **Terminate connections (if necessary):** Before dropping the database, it's crucial to ensure no one is connected to it. You can list active connections and then terminate them.

   * **List active connections:**

     ```sql
     SELECT pg_terminate_backend(pid)
     FROM pg_stat_activity
     WHERE datname = 'your_database_name';
     ```

     Replace `'your_database_name'` with the actual name of the database you want to drop. This query will generate `pg_terminate_backend` commands for each active connection.

   * **Terminate connections (manually or in a script):** You can then execute the output of the previous query to terminate the connections. Be cautious when doing this, as terminating connections can interrupt users' work.

   * **Forcefully terminate all connections (less graceful):**  Alternatively, you can use a more forceful option, but this should be used with caution:

     ```sql
     SELECT pg_terminate_backend(pg_stat_activity.pid)
     FROM pg_stat_activity
     WHERE pg_stat_activity.datname = 'your_database_name'
       AND pid <> pg_backend_pid();
     ```

     This query terminates all connections to the target database except the current connection.

4. **Drop the database:** Once you've ensured there are no active connections, you can execute the `DROP DATABASE` command:

   ```sql
   DROP DATABASE your_database_name;
   ```

   Replace `your_database_name` with the actual name of the database you want to delete.

**Example using `psql`:**

Let's say you want to drop a database named `mydatabase`.

1. Connect to PostgreSQL (e.g., using `psql postgres`).

2. List databases to confirm the name:

   ```sql
   \l
   ```

3. Try to terminate connections:

   ```sql
   SELECT pg_terminate_backend(pid)
   FROM pg_stat_activity
   WHERE datname = 'mydatabase';
   ```

   Execute the output of the above query if it returns any rows.

4. Drop the database:

   ```sql
   DROP DATABASE mydatabase;
   ```

## Switch to Another Database

```bash
\c <database_name>
```

## List All Tables

```bash
\dt
```

- To list tables from all schemas, use `\dt *.*`.

## Describe a Table

```bash
\d <table_name>
```

- For more detailed information, use `\d+ <table_name>`.

## List All Schemas

```bash
\dn
```

## List All Functions

```bash
\df
```

## List All Views

```bash
\dv
```

## List All Users and Their Roles

```bash
\du
```

- To retrieve information for a specific user, use `\du <username>`.

## Execute Bash Commands

```bash
\<bash_command>
```

## Export Table as CSV

```bash
\copy (SELECT * FROM <table_name>) TO 'file_path_and_name.csv' WITH CSV
```

## Pretty-Format Query Results

```bash
\x
```

## Show Help

```bash
\?
