# Noshi

Japanese noshi (熨斗) envelope generator web application.

## Live App

Production: https://noshi.onrender.com/

## Tech Stack

- **Ruby**: 3.3.6
- **Rails**: 8.1.1
- **Frontend**: Hotwire (Turbo + Stimulus), ImportMaps, Tailwind CSS 4
- **Deployment**: Kamal 2 on Hetzner
- **Cache/Session Store**: Redis 7

## Features

- Uses an internal JS class to track changes and encode them in a form
- Uses Hotwire to trigger image generation with htmlToImage
- ActiveJob for MiniMagick noshi generation (currently commented out)

## Removed Dependencies

- PostgreSQL (no database required)
- Devise (no authentication required)
- ActiveStorage with GCS

## Development

### Prerequisites

- Ruby 3.3.6
- Redis (for Action Cable and caching)
- Node.js (for asset compilation)

### Setup

```bash
# Install dependencies
bundle install

# Start the development server
bin/dev
```

The app should now be available at http://localhost:3000

## Testing

Tests with MiniTest (no tests currently implemented)

## Deployment

This application is configured to deploy to Hetzner using Kamal 2.

For detailed deployment instructions, see [DEPLOYMENT.md](DEPLOYMENT.md)

### Quick Deploy

```bash
# First time setup
bin/kamal setup

# Subsequent deploys
bin/kamal deploy
```

## License

All rights reserved.
