# PostgreSQL Cheat Sheet

## Connect to a Database

```bash
psql -U postgres -d <database_name>
```

## List All Databases

```bash
\l
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
