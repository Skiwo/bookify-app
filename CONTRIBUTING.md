# Contributing to Bookify

Thank you for your interest in contributing to Bookify!

## Getting Started

1. Fork the repository
2. Clone your fork: `git clone https://github.com/YOUR_USERNAME/bookify-app.git`
3. Install dependencies: `bundle install`
4. Set up the database: `rails db:setup`
5. Copy `.env.sample` to `.env` and fill in your POP sandbox credentials
6. Start the server: `rails s`

## Development

- Ruby 3.2.0
- Rails 8.0
- PostgreSQL

Emails in development open in the browser via `letter_opener`.

## Pull Requests

1. Create a feature branch from `main`
2. Write tests for new functionality
3. Ensure all tests pass: `bundle exec rspec`
4. Submit a pull request with a clear description

## Code Style

Follow standard Ruby and Rails conventions. No linter is enforced, but keep code clean and readable.

## Reporting Issues

Use GitHub Issues. Include steps to reproduce, expected behavior, and actual behavior.
