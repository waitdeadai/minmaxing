"""FTS5 search with bm25 ranking for minmaxing memory system."""

from memory.sqlite_db import MemoryDB

# Tier string to integer mapping for MemoryDB
TIER_MAP = {
    "semantic": 2,
    "error-solutions": 4,
}
VALID_TIERS = tuple(TIER_MAP.keys())


def search(query: str, tier: str, limit: int = 10) -> list[dict]:
    """Search FTS5 table for given tier using bm25 ranking.

    Args:
        query: Search query string.
        tier: Memory tier to search ("semantic" or "error-solutions").
        limit: Maximum number of results to return (default 10).

    Returns:
        List of dicts with keys: memory_id, text, rank, confidence, tags.

    Raises:
        ValueError: If tier is not "semantic" or "error-solutions".
    """
    if not query:
        return []

    if tier not in VALID_TIERS:
        raise ValueError(f"Invalid tier: {tier}. Must be one of {VALID_TIERS}")

    db = MemoryDB()
    tier_num = TIER_MAP[tier]

    # Use MemoryDB's built-in search method
    results = db.search(query=query, tier=tier_num, limit=limit)

    db.close()
    return results