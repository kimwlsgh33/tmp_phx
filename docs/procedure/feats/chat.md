# Create a basic chat functionality

## Procedure

1. Chat Context ( `lib/phx_chat/chat.ex` )

- Handles PubSub functionality for broadcasting messages
- Provids subscribe and broadcast functions

2. Chat LiveView ( `lib/phx_chat_web/live/chat_live.ex` )

- Manages the chat state and real-time updates
- Handles message sending and receiving
- Assigns random usernames for chat prarticipants

3. Chat Template ( `lib/phx_chat_web/live/chat_live.html.heex` )

- Mordern UI with message bubbles
- Different colors for sent and received messages
- Timestamps and usernames for each message
- Responsive design with Tailwind CSS

4. Router Update ( `lib/phx_chat_web/router.ex` )

- Added `/chat` route that renders the chat LiveView

## To use this

Open multiple browser tabs and navigate to `localhost:4000/chat` to chat with other users.
