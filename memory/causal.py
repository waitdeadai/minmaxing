"""Causal graph tracking for minmaxing memory system."""

from memory.sqlite_db import MemoryDB


def get_success_factors(limit: int = 5) -> list[dict]:
    """Return top factors correlated with success.

    Args:
        limit: Maximum number of factors to return

    Returns:
        List of dicts with keys: factor, weight, observations
        Sorted by weight descending (highest success correlation first)
    """
    db = MemoryDB()
    conn = db._conn
    cursor = conn.cursor()

    cursor.execute(
        """SELECT factor, weight, observations FROM causal_edges
           WHERE observations > 0
           ORDER BY weight DESC
           LIMIT ?""",
        (limit,),
    )
    rows = cursor.fetchall()
    db.close()

    return [
        {
            "factor": row["factor"],
            "weight": row["weight"],
            "observations": row["observations"],
        }
        for row in rows
    ]


def get_failure_factors(limit: int = 5) -> list[dict]:
    """Return top factors correlated with failure.

    Args:
        limit: Maximum number of factors to return

    Returns:
        List of dicts with keys: factor, weight, observations
        Sorted by weight ascending (lowest weight = most failure correlation)
    """
    db = MemoryDB()
    conn = db._conn
    cursor = conn.cursor()

    cursor.execute(
        """SELECT factor, weight, observations FROM causal_edges
           WHERE observations > 0
           ORDER BY weight ASC
           LIMIT ?""",
        (limit,),
    )
    rows = cursor.fetchall()
    db.close()

    return [
        {
            "factor": row["factor"],
            "weight": row["weight"],
            "observations": row["observations"],
        }
        for row in rows
    ]


def add_causal_edge(factor: str, outcome: str) -> None:
    """Add or update a causal edge from factor to outcome.

    Args:
        factor: Description of the factor (e.g., "test_first", "skip_review")
        outcome: "success" or "failure"
    """
    db = MemoryDB()
    db.add_causal_edge(factor=factor, outcome=outcome, weight=0.5 if outcome == "success" else 0.3)
    db.close()


def record_outcome(factors: list[str], outcome: str) -> None:
    """Record that a task had these factors and resulted in outcome.

    Args:
        factors: List of factor strings describing the task
        outcome: "success" or "failure"
    """
    for factor in factors:
        add_causal_edge(factor, outcome)
