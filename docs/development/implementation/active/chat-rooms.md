# Chat Rooms Implementation Plan

## Overview

## Implementation Details
- Location in codebase:
  - Channels: `lib/myapp_web/channel/chat_channel.ex`
  - Socket handlers: `lib/myapp_web/socket/user_socket.ex`
- Dependencies
- Technical specifications

## Task Breakdown

### 1. Implement Channel Layer (lib/myapp_web/channel/)
Handles WebSocket connections, message broadcasting, and channel-specific functionality.

#### Channels
Handles events from clients bi-directionally and persistent connections.

- Add real time chat functionality `chat_channel.ex` module (by jaerok)

- Add real time room-specific channel `room_channel.ex` module
   - Implement `join/3` to subscribe topic
   - Implement `terminate/2` to unsubscribe topic
   - Implement `handle_in/3` to handle incoming messages
   - Implement `handle_out/3` to send messages to the room

#### Socket Handler
- Add socket handler `user_socket.ex`
   - Add channel route to `user_socket.ex`
   - Define `channel "room:*", MyappWeb.ChatChannel`

- Implement `connect/3` callback to connect to the socket
   - Return `{:ok, socket}` if successful

### 2. Implement Context Layer (lib/myapp/chat/)
Create a new context for chat-related business logic.
This would handle persistence, chat room management, and message history.

- Add the context module for chat functionality `chat.ex`

### 3. Implement Schema Layer (lib/myapp/chat/)
Define the schema for chat rooms and messages.
These handle data structure and database interactions.

- Add schema and logic for chat room `room.ex`
- Add schema and logic for chat message `message.ex`

### 4. Create the Database Migration for `rooms` and `messages`

- Create the migrations for our rooms and messages tables:
   ```bash
   mix ecto.gen.migration create_chat_rooms
   ```

   - Add the `rooms` table to the migration:
      ```elixir
      def change do
        create table(:rooms) do
          add :name, :string, null: false
          add :description, :text
          add :slug, :string

          timestamps()
        end

        create index(:rooms, [:slug])
      end
      ```

- Create the migration for messages:
   ```bash
   mix ecto.gen.migration create_chat_messages
   ```

   - Add the `messages` table to the migration:
      ```elixir
      def change do
        create table(:messages) do
          add :content, :string
          add :user_id, :integer
          add :username, :string
          add :room_id, :integer

          timestamps()
        end

        create index(:messages, [:room_id])
        create index(:messages, [:inserted_at])
      end
      ```

- Update the socket configuration to handle our chat channels:
   ```elixir
   # lib/myapp_web/socket/user_socket.ex
   channel "room:*", MyappWeb.RoomChannel
   ```

- Migrate the database:
   ```bash
   mix ecto.migrate
   ```

### 5. Set up the front-end to connect to these channels

- Created chat.js with:
   - Socket connection setup
   - Room channel joining
   - Message sending and receiving
   - Message display functionality
   - Username management

- Created chat.css with styles for:
   - Chat container layout
   - Message bubbles
   - Input form
   - Responsive design
   
- Created show.html.heex template for the chat room interface

- Updated app.js to:
   - Import the chat functionality
   - Initialize chat when the page loads

- Updated app.css to import the chat styles

#### Usage Example

1. Create a room using the Chat context:
```elixir
Myapp.Chat.create_room(%{name: "General", description: "My First Room"})
```
2. Navigate to the room's page (you'll need to set up the route and controller, would you like me to help with that?)

3. The chat interface will automatically:
   - Prompt for username on first visit
   - Connect to the room channel
   - Display existing messages
   - Allow sending new messages

## Integration Plan
How this feature will be integrated into the existing system.

## Testing Requirements
- Unit tests
- Integration tests
- Validation criteria

## Timeline
- Estimated start date
- Major milestones
- Target completion date

