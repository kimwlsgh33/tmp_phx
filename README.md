
## Features

- [LiveView]

- 초기연결
  - 첫 접속시 일반적 HTTP 요청-응답으로 페이지 로드
  - WebSocket 연결이 자동으로 설정됨.

- 실시간 업데이트
  - WebSocket을 통해 서버와 클라이언트가 지속적으로 연결 유지
  - 양방향 통신이 가능하여 데이터 변경시 즉시 반영
  - 전체 페이지 새로고침을 하지 않아도 필요한 부분만 업데이트 가능

Myapp_web/ live/ counter_live 확인할것
이름_live를 쓰는것이 약속임
- [Key feature 2]
- [Key feature 3]

## Quick Start

1. **Setup Development Environment**
   ```bash
   # Install dependencies
   mix setup
   
   # Start Phoenix server
   mix phx.server
   ```

2. Visit [`localhost:4000`](http://localhost:4000) in your browser

## Development

For detailed development documentation, please see our [documentation guides](docs/README.md). Key resources:

- [Getting Started Guide](docs/getting-started/installation.md)
- [Contributing Guidelines](docs/CONTRIBUTING.md)
- [Development Guidelines](docs/development/README.md)

## Architecture Overview

This project follows Phoenix's standard architecture:

- Phoenix LiveView for real-time features
- PostgreSQL database
- [Other key architectural decisions]

## Documentation

Comprehensive documentation is available in the [docs](docs/) directory:

- [Installation & Setup](docs/getting-started/installation.md)
- [API Documentation](docs/api/README.md)
- [Development Guidelines](docs/development/README.md)
- [Deployment Guides](docs/deployment/README.md)

## Contributing

We welcome contributions! Please see our [Contributing Guide](docs/CONTRIBUTING.md) for details.

## License

[Your license information]

## Learn More

- [Phoenix Framework](https://www.phoenixframework.org/)
- [Phoenix Guides](https://hexdocs.pm/phoenix/overview.html)
- [Phoenix Documentation](https://hexdocs.pm/phoenix)
- [Elixir Forum](https://elixirforum.com/c/phoenix-forum)
