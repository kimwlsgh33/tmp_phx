# Phoenix Map Rendering Error

## Error Message
```
protocol Phoenix.HTML.Safe not implemented for type Map. This protocol is implemented for the following type(s)
```

## Problem Description
This error occurs when trying to directly render a map in a Phoenix template using `<%= @map_variable %>`. Phoenix templates require all rendered content to implement the `Phoenix.HTML.Safe` protocol, which maps do not implement by default.

## Example of Problematic Code
```heex
<div>
  <%= @privacy_policy %>  <!-- @privacy_policy is a map -->
</div>
```

## Solution
Instead of trying to render the map directly, you should:
1. Access specific map fields using pattern matching or key access
2. Handle both map and string cases if your variable could be either
3. Iterate through map contents using comprehensions

### Example Solution
```heex
<div>
  <%= if is_binary(@privacy_policy) do %>
    <%= @privacy_policy %>
  <% else %>
    <div>
      <%= if @privacy_policy["title"] do %>
        <h1><%= @privacy_policy["title"] %></h1>
      <% end %>
      
      <%= for item <- @privacy_policy["items"] || [] do %>
        <div>
          <%= item["name"] %>
        </div>
      <% end %>
    </div>
  <% end %>
</div>
```

## Key Points
- Never render a map directly in a template
- Use pattern matching to safely access map fields
- Handle potential nil values with the `||` operator
- Use comprehensions (`for`) to iterate over lists in maps
- Consider converting complex maps to structs if they have a fixed structure

## Related
- [Phoenix.HTML.Safe Protocol Documentation](https://hexdocs.pm/phoenix_html/Phoenix.HTML.Safe.html)
- [Phoenix Template Guide](https://hexdocs.pm/phoenix/templates.html)
