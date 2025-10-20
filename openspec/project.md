# Project Context

## Purpose
This project provides a bootstrap script and configuration for setting up a development environment with opencode tools, including Devbox, Nushell, and Simon CLI. It enables spec-driven development using OpenSpec for managing project specifications, change proposals, and implementation tracking.

## Tech Stack
- Shell scripting (Bash)
- Nushell for enhanced shell scripting
- Devbox for development environment management
- Git for version control
- Markdown for documentation and specifications
- OpenSpec CLI for spec-driven development

## Project Conventions

### Code Style
- Use Bash for shell scripts with proper error handling
- Follow POSIX shell standards where possible
- Use descriptive variable names in UPPER_CASE for environment variables
- Include comments for complex logic
- Use consistent indentation (tabs for shell scripts)

### Architecture Patterns
- Modular command structure with individual markdown files for each opencode command
- Separation of concerns between bootstrap scripts, specifications, and documentation
- Use of OpenSpec for managing specifications and change proposals

### Testing Strategy
- Manual testing of bootstrap scripts
- Validation through OpenSpec's built-in validation tools
- Integration testing of the full bootstrap process

### Git Workflow
- Use feature branches for changes
- Follow OpenSpec workflow for proposals and changes
- Commit messages should be descriptive and reference change IDs when applicable
- Use kebab-case for branch names

## Domain Context
This project operates in the domain of developer tooling and environment setup. It focuses on streamlining the onboarding process for projects using opencode and OpenSpec. Key concepts include:
- Bootstrap scripts for automated setup
- Command-based interfaces for opencode
- Spec-driven development methodology
- Development environment management

## Important Constraints
- Must work across different operating systems (macOS, Linux)
- Should minimize external dependencies during bootstrap
- Commands must be executable via opencode interface
- OpenSpec conventions must be strictly followed

## External Dependencies
- Devbox (https://www.jetify.com/devbox)
- Nushell (https://www.nushell.sh/)
- Simon CLI (https://github.com/simon/simon-cli)
- GitHub for repository cloning
- OpenSpec CLI tool
