# Set up database storage fo the chat messages.

## Procedure

1. Create a migration and schema

```bash
mix ecto.gen.migration create_messages
```

2. Create the Message schema ( `priv/repo/migratations/20241217*` )

3. Update the Chat context to work with the database ( `lib/phx_chat/chat.ex` )

4. Update the LiveView to load and store messages ( `lib/phx_chat_web/live/chat_live.ex` )

5. Update the template to use the database timestamps ( `lib/phx_chat_web/live/chat_live.html.heex` )

6. Run the migration to create the database table

```bash
mix ecto.migrate
```

## Key Takeaways

1. Create a `messages` table with:
  - `content` : The message text
  - `username` : The username of the sender
  - `timestamps` : Automatically tracks the creation and update times

2. Added `Message` schema and functions:
  - `Message.changeset/2` : Validates message data
  - `Message.list_recent/1` : Query for recent messages

3. Updated the Chat context with:
  - `create_message/1` : Stores messages in the database
  - `list_recent_messages/1` : Retrieves recent messages
  - Modified `broadcast_message/1` to save messages before broadcasting

4. Modified the LiveView to:
  - Load existing messages on mount
  - Store new messages in the database
  - use database timestamps for message display

## To use this

1. Restart your Phoenix server
2. Open `/chat` in multiple browser windows
3. Send some messages
4. Refresh the page - you'll see your messages are stil here!
