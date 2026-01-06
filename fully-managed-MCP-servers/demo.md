AI Assistant (Amazon Q / Kiro / Cursor / Cline)
        |
        | MCP (stdio)
        v
mcp-proxy-for-aws (local, uvx)
        |
        | SigV4 (IAM)
        v
AWS-hosted EKS MCP Server (preview)
https://eks-mcp.{region}.api.aws/mcp
        |
        v
EKS APIs + Kubernetes API + CloudWatch (read)



