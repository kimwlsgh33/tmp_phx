# Error

```bash
[debug] HANDLE EVENT "form_update" in PhxChatWeb.ChatLive
  Parameters: %{"key" => "1", "value" => "1"}
[error] GenServer #PID<0.677.0> terminating
** (FunctionClauseError) no function clause matching in PhxChatWeb.ChatLive.handle_event/3
    (phx_chat 0.1.0) lib/phx_chat_web/live/chat_live.ex:20: PhxChatWeb.ChatLive.handle_event("form_update", %{"key" => "1", "value" => "1"}, #Phoenix.LiveView.Socket<id: "phx-GBHoODQnPmVnlA_G", endpoint: PhxChatWeb.Endpoint, view: PhxChatWeb.ChatLive, parent_pid: nil, root_pid: #PID<0.677.0>, router: PhxChatWeb.Router, assigns: %{messages: [], username: "user753", __changed__: %{}, flash: %{}, live_action: nil, current_message: ""}, transport_pid: #PID<0.670.0>, ...>)
    (phoenix_live_view 1.0.1) lib/phoenix_live_view/channel.ex:508: anonymous fn/3 in Phoenix.LiveView.Channel.view_handle_event/3
    (telemetry 1.3.0) /Users/xxxx/devs/repos/phx_chat/deps/telemetry/src/telemetry.erl:324: :telemetry.span/3
    (phoenix_live_view 1.0.1) lib/phoenix_live_view/channel.ex:260: Phoenix.LiveView.Channel.handle_info/2
    (stdlib 6.2) gen_server.erl:2345: :gen_server.try_handle_info/3
    (stdlib 6.2) gen_server.erl:2433: :gen_server.handle_msg/6
    (stdlib 6.2) proc_lib.erl:340: :proc_lib.wake_up/3
Last message: %Phoenix.Socket.Message{topic: "lv:phx-GBHoODQnPmVnlA_G", event: "event", payload: %{"event" => "form_update", "type" => "keyup", "value" => %{"key" => "1", "value" => "1"}}, ref: "13", join_ref: "4"}
State: %{socket: #Phoenix.LiveView.Socket<id: "phx-GBHoODQnPmVnlA_G", endpoint: PhxChatWeb.Endpoint, view: PhxChatWeb.ChatLive, parent_pid: nil, root_pid: #PID<0.677.0>, router: PhxChatWeb.Router, assigns: %{messages: [], username: "user753", __changed__: %{}, flash: %{}, live_action: nil, current_message: ""}, transport_pid: #PID<0.670.0>, ...>, components: {%{}, %{}, 1}, topic: "lv:phx-GBHoODQnPmVnlA_G", serializer: Phoenix.Socket.V2.JSONSerializer, join_ref: "4", upload_names: %{}, upload_pids: %{}}
[debug] MOUNT PhxChatWeb.ChatLive
  Parameters: %{}
  Session: %{"_csrf_token" => "99mlrosRPH3asIzexxCAWyno"}
[debug] Replied in 395µs
^C
BREAK: (a)bort (A)bort with dump (c)ontinue (p)roc info (i)nfo
       (l)oaded (v)ersion (k)ill (D)b-tables (d)istribution
➜  phx_chat git:(feat/chat)                
```

# Solution

Modify the key in the `handle_event/3` function to match the key in the `form_update` event:

```elixir
@impl true
def handle_event("form_update", %{"value" => message}, socket) do
  {:noreply, assign(socket, current_message: message)}
end
```
