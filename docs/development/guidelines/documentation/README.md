# Documentation Guidelines

This guide explains how to write and maintain documentation in our project.

## Documentation Types

1. **Code Documentation**
   - Module documentation (`@moduledoc`)
   - Function documentation (`@doc`)
   - Type specifications (`@spec`)
   - Examples and doctests

2. **API Documentation**
   - API endpoints
   - Request/response formats
   - Authentication
   - Error responses

3. **User Guides**
   - Installation
   - Configuration
   - Usage examples
   - Troubleshooting

4. **Architecture Documentation**
   - System overview
   - Component interactions
   - Data flow diagrams
   - Database schema

## Writing Style

- Use clear, concise language
- Write in present tense
- Use active voice
- Include code examples
- Keep documentation up-to-date
- Use proper Markdown formatting

## Markdown Guidelines

### Headers
```markdown
# Main Title (H1)
## Section (H2)
### Subsection (H3)
```

### Code Blocks
- Use fenced code blocks with language
```markdown
​```elixir
def example_function do
  :ok
end
​```
```

### Links
- Use relative links when linking to other docs
- Use descriptive link text
```markdown
[Installation Guide](../getting-started/installation.md)
```

## Directory Structure

- Keep related docs together
- Use clear file names
- Include README.md in each directory
- Follow the established hierarchy

## Maintenance

- Review docs during PR reviews
- Update docs with code changes
- Remove outdated information
- Verify links periodically
- Keep examples current
