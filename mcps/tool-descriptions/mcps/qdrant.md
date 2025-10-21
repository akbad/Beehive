# Qdrant MCP

## Scaling strategies

### Handling large collections/datasets of memories

1. Pre-create the collection in Qdrant with on-disk vectors or on-disk HNSW to reduce RAM pressure
2. Then, point the MCP to it (using `COLLECTION_NAME=...`). 

> *This is internal Qdrant DB tuning, independent of the Qdrant MCP server*
