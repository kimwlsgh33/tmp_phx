# Authentication

## Procedure

1. Add user authentication using Phoenix's built-in authentication system.

```bash
mix phx.gen.auth Accounts User users
```

2. Refetch dependencies

```bash
mix deps.get
```

3. Update repository

```bash
mix ecto.migrate
```

4. Modify the Message schema to reference users ( `priv/repo/migrations/20241217*` )

5. Update the Message schema ( `lib/phx_chat/chat/message.ex` )

6. Update the chatLive module to require authentication ( `lib/phx_chat_web/live/chat_live.ex` )

7. Update the router to require authentication for the chat routes ( `lib/phx_chat_web/router.ex` )

8. Run the migration again to add the user reference to messages

```bash
mix ecto.migrate
```

9. Add a link to the chat in the navbar

## Key Takeaways

1. User Authentication System:
  - Registration at `/users/register`
  - Login at `/users/log_in`
  - Password reset functionality
  - Email confirmation (viewable at `/dev/mailbox`)

2. Message Updates:
  - Messages are now associated with users
  - User's email is used as the username
  - Messages are permanently linked to user accounts

3. Security:
  - Chat is only accessible to authenticated users
  - Each message is tied to a specific user
  - Users must be logged in to view or send messages

## To use this

1. Visit `/users/register` to create an account

2. Check `/dev/mailbox` to confirm your email

3. Log in at `/users/log_in`

4. Click the "Chat" link in the navbar or visit `/chat`

5. Start chatting!
