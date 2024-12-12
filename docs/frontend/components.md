# LiveView Components

This document covers the LiveView components used in our Phoenix application.

## Component Overview

### Stateless Components
Components that don't maintain their own state.

### Stateful Components
Components that manage their own state using `handle_event/3`.

## Component Guidelines

### Naming Conventions
- Use descriptive, action-based names
- Follow Phoenix naming conventions

### Component Structure
```elixir
defmodule MyAppWeb.Components.Button do
  use Phoenix.LiveComponent

  def mount(socket) do
    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    <button class={@class} phx-click="click">
      <%= @label %>
    </button>
    """
  end
end
```

## Best Practices

### State Management
- Keep state minimal
- Use assigns for configuration
- Handle events efficiently

### Performance
- Minimize updates
- Use `phx-update` appropriately
- Implement `update/2` when needed

## Testing Components

### Unit Tests
```elixir
defmodule MyAppWeb.Components.ButtonTest do
  use MyAppWeb.ConnCase
  import Phoenix.LiveViewTest
end
```

### Integration Tests
Testing components within LiveView contexts.
