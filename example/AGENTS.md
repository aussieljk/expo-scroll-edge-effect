
## Personal iOS builds

Use the ios-builds MCP at `https://ios-builds.ljk.dev/mcp/<panel key>` to build
or run Metro. Read `~/p/labs/ios-builds/README.md` for tool and profile details.
`testflight` is a bundled release; `testflight-dev` is a store-signed Debug
client that wakes Metro through the shared `ios-builds-dev-client` package.
Both use the same store bundle ID. Store builds submit automatically.
Keep SDK 58 native dependencies aligned with `bunx expo install --fix`.
