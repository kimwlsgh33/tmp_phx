# Error

```bash
Compiling 1 file (.ex)
    error: undefined function link/1 (expected PhxChatWeb.Layouts to define such a function or for it to be imported, but none are available)
    │
 13 │         <%= link "Chat", to: ~p"/chat", class: "hover:text-zinc-700" %>
    │             ^^^^
    │
    └─ lib/phx_chat_web/components/layouts/app.html.heex:13:13: PhxChatWeb.Layouts.app/1


== Compilation error in file lib/phx_chat_web/components/layouts.ex ==
** (CompileError) lib/phx_chat_web/components/layouts.ex: cannot compile module PhxChatWeb.Layouts (errors have been logged)
```

# Solution

```elixir
<.link href={~p"/chat"} class="hover:text-zinc-700">Chat</.link>
```
