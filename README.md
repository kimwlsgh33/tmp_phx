# Phoenix Documentation Project

A Phoenix-based project for creating and displaying documentation for various services and platforms.

## Features

- **Phoenix Framework**: Built with Elixir and Phoenix for robustness and scalability
- **LiveView**: Real-time updates without refreshing the page
- **Documentation System**: Comprehensive markdown-based documentation for various services
- **Responsive Design**: Fully responsive documentation UI that works across all device sizes

## Quick Start

1. **Setup Development Environment**
   ```bash
   # Install dependencies
   mix deps.get
   
   # Setup database
   mix ecto.setup
   
   # Install Node.js dependencies
   cd assets && npm install && cd ..
   
   # Start Phoenix server
   mix phx.server
   ```

2. Visit [`localhost:4000`](http://localhost:4000) in your browser

## Documentation

This project contains documentation for various platforms:

- [Claude-Code](docs/Claude-Code.md) - Documentation for Claude AI coding capabilities
- [Cloudflare](docs/Cloudflare.md) - Cloudflare service documentation
- [Instagram](docs/Instagram.md) - Instagram platform documentation
- [LLC](docs/LLC.md) - LLC formation documentation
- [TikTok](docs/Tiktok.md) - TikTok platform documentation
- [YouTube](docs/Youtube.md) - YouTube platform documentation

## Development

The documentation UI components have been improved with:

- Fully responsive design across all device sizes
- Proper handling of code blocks and tables with horizontal scrolling
- Dynamic table of contents generation based on headings
- Optimized content layout with better spacing
- Enhanced visual indicators for scrollable content

## Project Structure

The project follows the standard Phoenix structure with the following key directories:

- `assets/` - Frontend assets (CSS, JS)
- `config/` - Application configuration
- `docs/` - Markdown documentation files
- `lib/` - Elixir source code
- `priv/` - Private application files
- `test/` - Test files

## Contributing

We welcome contributions to our documentation! Please see our guidelines for details.

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Learn More

- [Phoenix Framework](https://www.phoenixframework.org/)
- [Phoenix LiveView](https://hexdocs.pm/phoenix_live_view)
- [Elixir Language](https://elixir-lang.org/)
