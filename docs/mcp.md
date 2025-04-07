
[Model Context Protocol](https://docs.anthropic.com/en/docs/agents-and-tools/mcp) is an open protocol allowing LLMs to interact with applications.

Chef-cli's `chef-cli mcp initial-mapping` subcommand implements an stdio-based MCP server, which provides tools for the AI to edit and test a local initial domain mapping file against a metadata file.

To use it, you would need to configure your MCP client. In case of Cursor, this means putting

```json
{
    "mcpServers": {
        "airdrop": {
            "command":  "chef-cli",
            "args":  [
                "mcp initial-mapping"
            ]
        }
    }
}
```
in `.cursor/mcp.json`, while for Claude Code, the same content goes to `.mcp.json` in the root of your project.


To guide the AI in using the tool, we recommend providing it with a 'rule' or 'prompt' file along the lines of:

```markdown
When asked to perform airdrop initial mapping:

-  refer to the metadata.json for the external domain metadata.

- use mappings.json as your initial domain mapping file.

-  Call 'use_mapping' to test out how the initial mapping behaves on the current metadata

-  Use MCP tools to manipulate the initial mapping when adding and removing record type mappings, or unmapping fields or mapping simple fields. For more complex field mappings you may edit the mapping file directly. Refer to the initial_mappings_schema.yaml for its proper format.

    If doing so, always use use_mapping to verify the mapping file is still valid.
```

You may need to modify the paths to the files you are directing the AI to.

As of April 2025, MCP is an experimental capability of chef-cli, and it might or might not work well with your chosen AI model and MCP client, we however observed good results using Cursor 0.47 and Claude Code, where the AI was able to prepare an initial mappings, given the metadata, with considerable autonomy (though still with developer oversight).