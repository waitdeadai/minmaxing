"""Auto-consolidation for minmaxing memory system.

Consolidation includes:
- Merging similar semantic memories (Jaccard > 0.80 on words, same category)
- Pruning semantic memories with confidence < 0.05
- Pruning procedural with success_rate < 0.3 (category='pattern' where success_rate < 0.3)
- Capping semantic at 500, procedural at 200 (keep highest confidence)
- Exponential decay by category-specific halflife
"""

import math
import re
from datetime import datetime, timedelta
from typing import Any, Dict, List, Optional, Set, Tuple

from memory.sqlite_db import MemoryDB


# Category-specific halflifes in days
HALFLIFES: Dict[str, int] = {
    "architecture": 90,
    "security": 60,
    "testing": 45,
    "debugging": 14,
    "default": 30,
}

# Consolidation thresholds
JACCARD_THRESHOLD = 0.80
SEMANTIC_MIN_CONFIDENCE = 0.05
PROCEDURAL_MIN_SUCCESS_RATE = 0.3
SEMANTIC_CAP = 500
PROCEDURAL_CAP = 200
DECAY_SKIP_DAYS = 7


def _get_halflife(category: str) -> int:
    """Get halflife in days for a category."""
    return HALFLIFES.get(category, HALFLIFES["default"])


def _tokenize(text: str) -> Set[str]:
    """Extract words from text for Jaccard comparison."""
    words = re.findall(r"[a-zA-Z0-9]+", text.lower())
    return set(words)


def _jaccard_similarity(set1: Set[str], set2: Set[str]) -> float:
    """Calculate Jaccard similarity between two sets."""
    if not set1 and not set2:
        return 0.0
    intersection = len(set1 & set2)
    union = len(set1 | set2)
    if union == 0:
        return 0.0
    return intersection / union


def _get_success_rate(memory: Dict[str, Any]) -> float:
    """Calculate success rate for a semantic memory."""
    success_count = memory.get("success_count", 0)
    failure_count = memory.get("failure_count", 0)
    total = success_count + failure_count
    if total == 0:
        return 0.5  # Default if no data
    return success_count / total


def _merge_memories(db: MemoryDB, ids: List[str], keep_id: str) -> None:
    """Merge multiple memories into one, keeping the highest confidence."""
    if len(ids) <= 1:
        return

    conn = db._conn

    # Get all memories to merge
    placeholders = ",".join("?" * len(ids))
    conn.execute(f"SELECT * FROM semantic WHERE memory_id IN ({placeholders})", ids)
    memories = conn.execute(f"SELECT * FROM semantic WHERE memory_id IN ({placeholders})", ids).fetchall()
    memories = [dict(m) for m in memories]

    if not memories:
        return

    # Find the memory with highest confidence to keep
    keep_memory = max(memories, key=lambda m: m["confidence"])

    # Merge content from all others into keep_id
    other_ids = [mid for mid in ids if mid != keep_memory["memory_id"]]
    if not other_ids:
        return

    # Get content from all memories
    all_contents = [m["text"] for m in memories]
    merged_text = " ".join(all_contents)

    # Update the kept memory with merged content
    conn.execute(
        "UPDATE semantic SET text = ? WHERE memory_id = ?",
        (merged_text, keep_id),
    )

    # Mark others as superseded
    other_placeholders = ",".join("?" * len(other_ids))
    conn.execute(
        f"UPDATE semantic SET superseded_by = ? WHERE memory_id IN ({other_placeholders})",
        [keep_id] + other_ids,
    )

    conn.commit()


def _table_exists(db: MemoryDB, table_name: str) -> bool:
    """Check if a table exists in the database."""
    result = db._conn.execute(
        "SELECT name FROM sqlite_master WHERE type='table' AND name=?",
        (table_name,),
    ).fetchone()
    return result is not None


def _prune_semantic_low_confidence(db: MemoryDB) -> int:
    """Prune semantic memories with confidence < SEMANTIC_MIN_CONFIDENCE."""
    if not _table_exists(db, "semantic"):
        return 0

    result = db._conn.execute(
        "DELETE FROM semantic WHERE confidence < ? AND superseded_by IS NULL",
        (SEMANTIC_MIN_CONFIDENCE,),
    )
    db._conn.commit()
    return result.rowcount


def _prune_procedural_low_success(db: MemoryDB) -> int:
    """Prune procedural memories (category='pattern') with success_rate < PROCEDURAL_MIN_SUCCESS_RATE."""
    if not _table_exists(db, "semantic"):
        return 0

    # Get all pattern memories and calculate success rate
    patterns = db._conn.execute(
        "SELECT memory_id, success_count, failure_count FROM semantic WHERE category = 'pattern' AND superseded_by IS NULL"
    ).fetchall()

    to_delete = []
    for p in patterns:
        success_count = p["success_count"]
        failure_count = p["failure_count"]
        total = success_count + failure_count
        if total > 0:
            success_rate = success_count / total
            if success_rate < PROCEDURAL_MIN_SUCCESS_RATE:
                to_delete.append(p["memory_id"])

    if not to_delete:
        return 0

    placeholders = ",".join("?" * len(to_delete))
    result = db._conn.execute(
        f"DELETE FROM semantic WHERE memory_id IN ({placeholders})",
        to_delete,
    )
    db._conn.commit()
    return result.rowcount


def _cap_memories(db: MemoryDB) -> Tuple[int, int]:
    """Cap semantic at SEMANTIC_CAP and procedural at PROCEDURAL_CAP.

    Returns:
        Tuple of (semantic_deleted, procedural_deleted)
    """
    semantic_deleted = 0
    procedural_deleted = 0

    # Cap semantic (excluding patterns which are procedural)
    if _table_exists(db, "semantic"):
        semantic_count = db._conn.execute(
            "SELECT COUNT(*) as count FROM semantic WHERE superseded_by IS NULL AND category != 'pattern'"
        ).fetchone()["count"]

        if semantic_count > SEMANTIC_CAP:
            excess = semantic_count - SEMANTIC_CAP
            result = db._conn.execute(
                """DELETE FROM semantic WHERE memory_id IN (
                    SELECT memory_id FROM semantic
                    WHERE superseded_by IS NULL AND category != 'pattern'
                    ORDER BY confidence ASC
                    LIMIT ?
                )""",
                (excess,),
            )
            semantic_deleted = result.rowcount
            db._conn.commit()

        # Cap procedural (category='pattern')
        procedural_count = db._conn.execute(
            "SELECT COUNT(*) as count FROM semantic WHERE category = 'pattern' AND superseded_by IS NULL"
        ).fetchone()["count"]

        if procedural_count > PROCEDURAL_CAP:
            excess = procedural_count - PROCEDURAL_CAP
            result = db._conn.execute(
                """DELETE FROM semantic WHERE memory_id IN (
                    SELECT memory_id FROM semantic
                    WHERE category = 'pattern' AND superseded_by IS NULL
                    ORDER BY (CASE WHEN (success_count + failure_count) > 0
                        THEN CAST(success_count AS REAL) / (success_count + failure_count)
                        ELSE 0.5 END) ASC
                    LIMIT ?
                )""",
                (excess,),
            )
            procedural_deleted = result.rowcount
            db._conn.commit()

    return semantic_deleted, procedural_deleted


def _merge_similar_semantic(db: MemoryDB) -> int:
    """Merge similar semantic memories (Jaccard > JACCARD_THRESHOLD, same category).

    Returns:
        Number of memories merged
    """
    if not _table_exists(db, "semantic"):
        return 0

    # Get all semantic memories (excluding patterns and superseded)
    cursor = db._conn.execute(
        "SELECT memory_id, text, category FROM semantic WHERE superseded_by IS NULL AND category != 'pattern' ORDER BY memory_id"
    )
    memories = cursor.fetchall()

    if len(memories) < 2:
        return 0

    memories = [dict(m) for m in memories]

    # Build index by category
    by_category: Dict[str, List[Tuple[str, str]]] = {}
    for m in memories:
        cat = m["category"] or "default"
        if cat not in by_category:
            by_category[cat] = []
        by_category[cat].append((m["memory_id"], m["text"]))

    merged_count = 0
    merged_ids: Set[str] = set()

    for category, category_memories in by_category.items():
        # Compare all pairs in same category
        for i in range(len(category_memories)):
            id1, content1 = category_memories[i]
            if id1 in merged_ids:
                continue

            tokens1 = _tokenize(content1)

            for j in range(i + 1, len(category_memories)):
                id2, content2 = category_memories[j]
                if id2 in merged_ids:
                    continue

                tokens2 = _tokenize(content2)
                similarity = _jaccard_similarity(tokens1, tokens2)

                if similarity > JACCARD_THRESHOLD:
                    # Merge into higher ID (usually newer)
                    keep_id = max(id1, id2)
                    merge_id = min(id1, id2)
                    _merge_memories(db, [merge_id, keep_id], keep_id)
                    merged_ids.add(merge_id)
                    merged_count += 1
                    break

    return merged_count


def _decay_memories(db: MemoryDB) -> Tuple[int, int]:
    """Apply exponential decay to memories based on category halflife.

    Skips memories reinforced within last DECAY_SKIP_DAYS days.
    Note: This database uses created_at for decay tracking, not last_reinforced.

    Returns:
        Tuple of (semantic_decayed, procedural_decayed)
    """
    semantic_decayed = 0
    procedural_decayed = 0
    now = datetime.now()
    current_time = now.timestamp()

    if not _table_exists(db, "semantic"):
        return 0, 0

    # Decay semantic memories (excluding patterns)
    semantic_memories = db._conn.execute(
        """SELECT memory_id, confidence, category, created_at
           FROM semantic
           WHERE superseded_by IS NULL AND category != 'pattern'"""
    ).fetchall()

    for m in semantic_memories:
        created_at = datetime.fromtimestamp(m["created_at"])
        days_since = (now - created_at).days

        # Skip if created within last 7 days
        if days_since < DECAY_SKIP_DAYS:
            continue

        halflife = _get_halflife(m["category"] or "default")
        new_confidence = m["confidence"] * math.pow(2, -days_since / halflife)

        db._conn.execute(
            "UPDATE semantic SET confidence = ? WHERE memory_id = ?",
            (new_confidence, m["memory_id"]),
        )
        semantic_decayed += 1

    db._conn.commit()

    # Decay procedural memories (category='pattern')
    procedural_memories = db._conn.execute(
        """SELECT memory_id, confidence, category, created_at
           FROM semantic
           WHERE category = 'pattern' AND superseded_by IS NULL"""
    ).fetchall()

    for m in procedural_memories:
        created_at = datetime.fromtimestamp(m["created_at"])
        days_since = (now - created_at).days

        if days_since < DECAY_SKIP_DAYS:
            continue

        halflife = _get_halflife(m["category"] or "default")
        new_confidence = m["confidence"] * math.pow(2, -days_since / halflife)

        db._conn.execute(
            "UPDATE semantic SET confidence = ? WHERE memory_id = ?",
            (new_confidence, m["memory_id"]),
        )
        procedural_decayed += 1

    db._conn.commit()

    return semantic_decayed, procedural_decayed


def consolidate() -> Dict[str, int]:
    """Run full consolidation: merge, prune, cap, and decay.

    Consolidation steps:
    1. Merge similar semantic memories (Jaccard > 0.80, same category)
    2. Prune semantic with confidence < 0.05
    3. Prune procedural with success_rate < 0.3
    4. Cap semantic at 500, procedural at 200
    5. Apply exponential decay based on category halflife

    Returns:
        Dictionary with counts of affected memories
    """
    db = MemoryDB()
    stats: Dict[str, int] = {}

    # Merge similar
    merged = _merge_similar_semantic(db)
    stats["merged"] = merged

    # Prune low confidence/procedural
    pruned_semantic = _prune_semantic_low_confidence(db)
    pruned_procedural = _prune_procedural_low_success(db)
    stats["pruned_semantic"] = pruned_semantic
    stats["pruned_procedural"] = pruned_procedural

    # Cap at limits
    capped_semantic, capped_procedural = _cap_memories(db)
    stats["capped_semantic"] = capped_semantic
    stats["capped_procedural"] = capped_procedural

    # Apply decay
    decayed_semantic, decayed_procedural = _decay_memories(db)
    stats["decayed_semantic"] = decayed_semantic
    stats["decayed_procedural"] = decayed_procedural

    # Update last consolidation time
    set_last_consolidation(datetime.now())

    db.close()
    return stats


def decay() -> Tuple[int, int]:
    """Apply exponential decay to all memories.

    Halflifes by category:
    - architecture: 90 days
    - security: 60 days
    - testing: 45 days
    - debugging: 14 days
    - default: 30 days

    Formula: confidence *= 2^(-days_since_created / halflife)
    Skips memories created within last 7 days.

    Returns:
        Tuple of (semantic_decayed, procedural_decayed)
    """
    db = MemoryDB()
    result = _decay_memories(db)
    db.close()
    return result


def get_last_consolidation() -> Optional[datetime]:
    """Get the datetime of last consolidation.

    Returns:
        Datetime of last consolidation or None if never run
    """
    if not _table_exists(MemoryDB(), "memory_meta"):
        return None

    db = MemoryDB()
    row = db._conn.execute(
        "SELECT value FROM memory_meta WHERE key = 'last_consolidation'"
    ).fetchone()
    db.close()

    if row is None:
        return None

    try:
        timestamp = float(row["value"])
        if timestamp == 0:
            return None
        return datetime.fromtimestamp(timestamp)
    except (ValueError, TypeError):
        return None


def set_last_consolidation(dt: datetime) -> None:
    """Update the last consolidation timestamp."""
    db = MemoryDB()
    now = dt.timestamp()
    db._conn.execute(
        "INSERT OR REPLACE INTO memory_meta (key, value, updated_at) VALUES (?, ?, ?)",
        ("last_consolidation", str(now), now),
    )
    db._conn.commit()
    db.close()


def get_episodes_since_consolidation() -> int:
    """Get count of episodes since last consolidation."""
    if not _table_exists(MemoryDB(), "memory_meta"):
        return 0

    db = MemoryDB()
    row = db._conn.execute(
        "SELECT value FROM memory_meta WHERE key = 'episode_count_since_consolidation'"
    ).fetchone()
    db.close()

    if row is None:
        return 0

    try:
        return int(row["value"])
    except (ValueError, TypeError):
        return 0


def increment_episode_count() -> int:
    """Increment the episode count since last consolidation.

    Returns:
        New episode count
    """
    db = MemoryDB()
    now = db._conn.execute("SELECT unixepoch()").fetchone()[0]

    row = db._conn.execute(
        "SELECT value FROM memory_meta WHERE key = 'episode_count_since_consolidation'"
    ).fetchone()
    current = int(row["value"]) if row and row["value"] else 0
    new_count = current + 1

    db._conn.execute(
        "INSERT OR REPLACE INTO memory_meta (key, value, updated_at) VALUES (?, ?, ?)",
        ("episode_count_since_consolidation", str(new_count), now),
    )
    db._conn.commit()
    db.close()

    return new_count


def _reset_episode_count() -> None:
    """Reset episode count to zero."""
    db = MemoryDB()
    now = db._conn.execute("SELECT unixepoch()").fetchone()[0]

    db._conn.execute(
        "INSERT OR REPLACE INTO memory_meta (key, value, updated_at) VALUES (?, ?, ?)",
        ("episode_count_since_consolidation", "0", now),
    )
    db._conn.commit()
    db.close()


def maybe_consolidate() -> Dict[str, Any]:
    """Check if consolidation is needed and run if so.

    Consolidation is triggered if:
    - Last consolidation > 24 hours ago, OR
    - Episode count since consolidation >= 10

    Returns:
        Dictionary with 'triggered' (bool) and consolidation stats if triggered
    """
    last_consolidation = get_last_consolidation()
    episode_count = get_episodes_since_consolidation()

    needs_consolidation = False

    if last_consolidation is None:
        # Never run, need to consolidate
        needs_consolidation = True
    elif (datetime.now() - last_consolidation) > timedelta(hours=24):
        # More than 24 hours since last consolidation
        needs_consolidation = True
    elif episode_count >= 10:
        # Too many episodes since last consolidation
        needs_consolidation = True

    if needs_consolidation:
        stats = consolidate()
        _reset_episode_count()
        return {"triggered": True, "stats": stats}

    return {"triggered": False, "stats": None}


if __name__ == "__main__":
    result = consolidate()
    print(f"Consolidation complete: {result}")
