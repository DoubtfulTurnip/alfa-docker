# ALFA Docker Container

Dockerized version of [ALFA (Automated Audit Log Forensic Analysis)](https://github.com/invictus-ir/ALFA) for Google Workspace.

## Prerequisites

- Docker installed and running
- Google Workspace admin account
- Google Cloud project with Admin SDK API enabled

## Building the Container

```bash
git clone https://github.com/DoubtfulTurnip/alfa-docker.git
cd alfa-docker
docker build -t alphadocker .
```

## Setup Instructions

### Step 1: Create Google Cloud Credentials

1. Go to [Google Cloud Console](https://console.cloud.google.com)
2. Create a new project or select an existing one
3. Enable the **Admin SDK API**
4. Create OAuth 2.0 credentials (Desktop application type)
5. Set authorized redirect URI to: `http://localhost:8089`
6. Download the credentials as `credentials.json`

Full guide: [ALFA Credentials Setup](https://github.com/invictus-ir/ALFA/blob/main/CREDENTIALS.md)

### Step 2: Initialize ALFA Project

```bash
# Create a new ALFA project
docker-compose run --rm alfa-init alfa init myproject
```

This creates the directory structure:
```
./projects/myproject/
├── config/
├── data/
└── output/
```

### Step 3: Add Your Credentials

Copy your `credentials.json` into the project config directory:

```bash
cp /path/to/credentials.json ./projects/myproject/config/credentials.json
```

### Step 4: Acquire Audit Logs

Run the acquire command to download Google Workspace audit logs:

```bash
PROJECT_NAME=myproject docker-compose run --rm alfa-acquire
```

**First time only:** You'll be prompted to authorize the application:
1. A browser window will open for Google OAuth
2. Sign in with your Workspace admin account
3. Grant the requested permissions
4. The authorization token will be saved automatically

**Optional filters:**
```bash
# Filter by log type
PROJECT_NAME=myproject ALFA_ARGS="--log_types admin" docker-compose run --rm alfa-acquire

# Filter by date range (RFC3339 format)
PROJECT_NAME=myproject ALFA_ARGS="--start_date 2024-01-01T00:00:00Z --end_date 2024-12-31T23:59:59Z" docker-compose run --rm alfa-acquire

# Filter by specific user
PROJECT_NAME=myproject ALFA_ARGS="--user_key user@domain.com" docker-compose run --rm alfa-acquire
```

Available log types: `admin`, `drive`, `login`, `calendar`, `token`, `groups`, `mobile`, `rules`, `saml`

### Step 5: Analyze Logs

Run automated analysis to identify suspicious activity:

```bash
PROJECT_NAME=myproject docker-compose run --rm alfa-analyze
```

This will:
- Map events to MITRE ATT&CK Cloud Framework
- Score events based on suspicious patterns
- Identify potential attack chains
- Generate findings in the output directory

### Step 6: Interactive Analysis (Optional)

Load logs into an interactive Python shell for manual investigation:

```bash
PROJECT_NAME=myproject docker-compose run --rm alfa-load
```

In the Python shell:
```python
from alfa.alfa import Alfa

# Load all logs
A = Alfa.load('all')

# View detected attack chains
A.subchains()

# Export findings to JSON
A.export_json('findings.json')

# Filter and explore specific events
A.events.head()
```

## Usage Examples

### Complete Workflow

```bash
# 1. Initialize project
docker-compose run --rm alfa-init alfa init investigation2024

# 2. Add credentials
cp ~/Downloads/credentials.json ./projects/investigation2024/config/

# 3. Acquire logs from specific date range
PROJECT_NAME=investigation2024 ALFA_ARGS="--start_date 2024-01-01T00:00:00Z" docker-compose run --rm alfa-acquire

# 4. Run automated analysis
PROJECT_NAME=investigation2024 docker-compose run --rm alfa-analyze

# 5. Review findings in output directory
ls -la ./projects/investigation2024/output/
```

### Using Direct Docker Commands

If you prefer not to use docker-compose:

```bash
# Interactive shell
docker run -it --rm \
  -v $(pwd)/projects:/projects \
  --network host \
  alphadocker bash

# Inside the container
cd /projects
alfa init myproject
cd myproject
# Copy credentials.json to config/
alfa acquire
alfa analyze
```

### Running in Background Shell

For quick access without docker-compose profiles:

```bash
docker-compose run --rm alfa-shell
```

This drops you into a bash shell with full ALFA access.

## Configuration

### Environment Variables

Create a `.env` file for default settings:

```bash
PROJECT_NAME=default_project
ALFA_ARGS=--log_types admin,login
```

### Custom ALFA Configuration

Customize ALFA behavior by editing config files in your project:

- `config/config.yml` - Kill chain discovery parameters
- `utils/mappings.yml` - Event to MITRE ATT&CK mappings

## Directory Structure

```
ALFA/
├── docker-compose.yml      # Service definitions
├── Dockerfile              # Container build instructions
├── .env.example            # Environment variable template
├── projects/               # ALFA projects (created on first use)
│   └── <project_name>/
│       ├── config/         # credentials.json goes here
│       ├── data/           # Downloaded audit logs
│       └── output/         # Analysis results
└── config/                 # Shared configuration (optional)
```

## Troubleshooting

### OAuth Authorization Issues

**Error:** `redirect_uri_mismatch`

**Solution:** Ensure your Google Cloud OAuth client has the redirect URI: `http://localhost:8089`

### Port 8089 Already in Use

**Error:** `Address already in use`

**Solution:** 
```bash
# Find process using port 8089
lsof -i :8089

# Kill the process or use a different port
# (requires modifying ALFA config)
```

### Credential Not Found

**Error:** `credentials.json not found`

**Solution:** Make sure credentials.json is in the correct location:
```bash
ls -la ./projects/<project_name>/config/credentials.json
```

### Permission Errors

**Error:** `Permission denied` when writing to projects directory

**Solution:**
```bash
# Fix permissions
chmod -R 755 ./projects
```

## Security Best Practices

- **Never commit credentials:** `credentials.json` and `token.json` are in `.gitignore`
- **Protect audit logs:** The `projects/` directory contains sensitive data
- **Restrict OAuth scope:** Only grant minimum required permissions
- **Rotate credentials:** Periodically regenerate OAuth credentials
- **Review access logs:** Monitor who accesses your Google Cloud project

## Available ALFA Commands

```bash
alfa init <project_name>          # Initialize new project
alfa acquire                       # Download audit logs
alfa analyze                       # Analyze logs for threats
alfa load                          # Interactive analysis shell
alfa --help                        # Show all options
```

## Additional Resources

- [ALFA GitHub Repository](https://github.com/invictus-ir/ALFA)
- [Google Workspace Admin SDK](https://developers.google.com/admin-sdk)
- [MITRE ATT&CK Cloud Matrix](https://attack.mitre.org/matrices/enterprise/cloud/)
