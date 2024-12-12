# Deployment Documentation

This directory contains comprehensive documentation about deployment processes, configurations, and best practices for the project.

## Directory Structure

```
deployment/
├── environments.md   # Deployment environments and configurations
├── operations.md     # Deployment operations and procedures
├── performance.md    # Performance monitoring and optimization
└── reliability.md    # Reliability and fault tolerance
```
## Deployment Methods

### Elixir Releases + Gigalixir

- Elixir Releases:
  - Elixir releases are the recommended deployment method for Phoenix applications.
  - They provide a lightweight and efficient way to deploy and manage the application.
  - Elixir releases are built using the `mix release` command, which creates a self-contained executable file.

- Gigalixir:
  - Gigalixir is a deployment platform that simplifies the deployment and management of Elixir applications.
  - It provides a web-based interface for deploying and managing releases, as well as monitoring and logging.
  - Gigalixir integrates with popular cloud providers like AWS and Heroku, allowing for seamless deployment to the cloud.

## Installation

### Homebrew

```bash
brew tap gigalixir/brew
brew install gigalixir
```

## Deployment

### Initial Setup

- Gigalixir setup
```bash
gigalixir login
gigalixir create -n $APP_NAME

```

- Versioning for Gigalixir
```bash
echo 'elixir_version=1.14.3' > elixir_buildpack.config
echo 'erlang_version=24.3.4' >> elixir_buildpack.config
echo 'node_version=12.16.3' > phoenix_static_buildpack.config
```

- commit
```bash
git add .
git commit -m "Set Elixir, Erlang, and Node version"
```

### Deployment

```bash
# You must merge into main first
git push gigalixir
```

### Guidelines

https://hexdocs.pm/phoenix/gigalixir.html#provisioning-a-database


### Release

You can see the resule of the deployment in the following URL:
https://tmpphx.gigalixirapp.com/
