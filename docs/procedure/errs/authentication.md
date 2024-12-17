# Error

```bash
[error] ** (Postgrex.Error) ERROR 42703 (undefined_column) column m0.user_id does not exist

    query: SELECT m0."id", m0."content", m0."username", m0."user_id", m0."inserted_at", m0."updated_at" FROM "messages" AS m0 ORDER BY m0."inserted_at" DESC LIMIT $1
    (ecto_sql 3.12.1) lib/ecto/adapters/sql.ex:1096: Ecto.Adapters.SQL.raise_sql_call_error/1
    (ecto_sql 3.12.1) lib/ecto/adapters/sql.ex:994: Ecto.Adapters.SQL.execute/6
    (ecto 3.12.5) lib/ecto/repo/queryable.ex:232: Ecto.Repo.Queryable.execute/4
    (ecto 3.12.5) lib/ecto/repo/queryable.ex:19: Ecto.Repo.Queryable.all/3
    (phx_chat 0.1.0) lib/phx_chat_web/live/chat_live.ex:15: PhxChatWeb.ChatLive.mount/3
    (phoenix_live_view 1.0.1) lib/phoenix_live_view/utils.ex:348: anonymous fn/6 in Phoenix.LiveView.Utils.maybe_call_live_view_mount!/5
    (telemetry 1.3.0) /Users/xxxx/devs/repos/phx_chat/deps/telemetry/src/telemetry.erl:324: :telemetry.span/3
    (phoenix_live_view 1.0.1) lib/phoenix_live_view/static.ex:320: Phoenix.LiveView.Static.call_mount_and_handle_params!/5
    (phoenix_live_view 1.0.1) lib/phoenix_live_view/static.ex:155: Phoenix.LiveView.Static.do_render/4
    (phoenix_live_view 1.0.1) lib/phoenix_live_view/controller.ex:39: Phoenix.LiveView.Controller.live_render/3
    (phoenix 1.7.18) lib/phoenix/router.ex:484: Phoenix.Router.__call__/5
    (phx_chat 0.1.0) lib/phx_chat_web/endpoint.ex:1: PhxChatWeb.Endpoint.plug_builder_call/2
    (phx_chat 0.1.0) deps/plug/lib/plug/debugger.ex:136: PhxChatWeb.Endpoint."call (overridable 3)"/2
    (phx_chat 0.1.0) lib/phx_chat_web/endpoint.ex:1: PhxChatWeb.Endpoint.call/2
    (phoenix 1.7.18) lib/phoenix/endpoint/sync_code_reload_plug.ex:22: Phoenix.Endpoint.SyncCodeReloadPlug.do_call/4
    (bandit 1.6.1) lib/bandit/pipeline.ex:127: Bandit.Pipeline.call_plug!/2
    (bandit 1.6.1) lib/bandit/pipeline.ex:36: Bandit.Pipeline.run/4
    (bandit 1.6.1) lib/bandit/http1/handler.ex:12: Bandit.HTTP1.Handler.handle_data/3
    (bandit 1.6.1) lib/bandit/delegating_handler.ex:18: Bandit.DelegatingHandler.handle_data/3
    (bandit 1.6.1) /Users/xxxx/devs/repos/phx_chat/deps/thousand_island/lib/thousand_island/handler.ex:417: Bandit.DelegatingHandler.handle_continue/2
```

# Solution

