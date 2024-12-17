# Error

```bash
23:15:16.695 [info] == Running 20241217140730 PhxChat.Repo.Migrations.AddUserIdToMessages.change/0 forward

23:15:16.695 [info] alter table messages
** (Postgrex.Error) ERROR 23502 (not_null_violation) column "user_id" of relation "messages" contains null values

    table: messages
    column: user_id
    (ecto_sql 3.12.1) lib/ecto/adapters/sql.ex:1096: Ecto.Adapters.SQL.raise_sql_call_error/1
    (elixir 1.17.3) lib/enum.ex:1703: Enum."-map/2-lists^map/1-1-"/2
    (ecto_sql 3.12.1) lib/ecto/adapters/sql.ex:1203: Ecto.Adapters.SQL.execute_ddl/4
    (ecto_sql 3.12.1) lib/ecto/migration/runner.ex:348: Ecto.Migration.Runner.log_and_execute_ddl/3
    (elixir 1.17.3) lib/enum.ex:1703: Enum."-map/2-lists^map/1-1-"/2
    (ecto_sql 3.12.1) lib/ecto/migration/runner.ex:311: Ecto.Migration.Runner.perform_operation/3
    (stdlib 6.2) timer.erl:595: :timer.tc/2
    (ecto_sql 3.12.1) lib/ecto/migration/runner.ex:25: Ecto.Migration.Runner.run/8
```

# Solution

## Create a New Migration to Handle Existing Data first

```bash
mix ecto.gen.migration update_user_id_in_messages
```
