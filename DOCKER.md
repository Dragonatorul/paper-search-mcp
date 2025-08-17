# Docker Image Available

The Paper Search MCP server is available as a Docker image for easy deployment.

## Usage

Add this configuration to your Claude Desktop config:

```json
{
  "mcpServers": {
    "paper-search": {
      "command": "docker",
      "args": [
        "run",
        "-i",
        "--rm",
        "ghcr.io/dragonatorul/paper-search-mcp:latest"
      ]
    }
  }
}
```

## Building Locally

```bash
docker build -t paper-search-mcp .
docker run -i --rm paper-search-mcp
```

