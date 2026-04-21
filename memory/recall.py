"""Adaptive retrieval for minmaxing memory system."""

from memory.sqlite_db import MemoryDB
from memory.causal import get_success_factors
from memory.search import search

# Depth configurations: (semantic_count, procedural_count, error_solutions_count, include_episodes)
DEPTH_CONFIG = {
    "simple": {
        "semantic": 3,
        "procedural": 0,
        "error_solutions": 0,
        "episodes": False,
    },
    "medium": {
        "semantic": 5,
        "procedural": 3,
        "error_solutions": 0,
        "episodes": False,
    },
    "complex": {
        "semantic": 8,
        "procedural": 4,
        "error_solutions": 3,
        "episodes": True,
    },
}

# Keywords for automatic depth detection
SIMPLE_KEYWORDS = ["fix", "typo", "rename", "bump", "update config"]
COMPLEX_KEYWORDS = ["refactor", "migrate", "architecture", "design", "system"]


def _detect_depth(task_description: str) -> str:
    """Detect retrieval depth from task description keywords."""
    task_lower = task_description.lower()

    simple_count = sum(1 for kw in SIMPLE_KEYWORDS if kw in task_lower)
    complex_count = sum(1 for kw in COMPLEX_KEYWORDS if kw in task_lower)

    if complex_count > simple_count:
        return "complex"
    elif simple_count > 0:
        return "simple"
    return "medium"


def recall(task_description: str, depth: str = "medium") -> dict:
    """
    Adaptive retrieval from minmaxing memory system.

    Args:
        task_description: Description of the current task
        depth: Retrieval depth - "simple", "medium", or "complex".
               If "auto", depth is detected from task_description keywords.

    Returns:
        dict with keys: semantic, procedural, error_solutions, causal_factors
    """
    if depth == "auto":
        depth = _detect_depth(task_description)

    config = DEPTH_CONFIG[depth]

    db = MemoryDB()
    results = {
        "semantic": [],
        "procedural": [],
        "error_solutions": [],
        "causal_factors": [],
    }

    # Semantic memories via FTS5 search
    if config["semantic"] > 0:
        semantic_results = search(
            task_description,
            tier="semantic",
            limit=config["semantic"],
        )
        results["semantic"] = semantic_results

    # Procedural memories - use semantic tier for now (procedural not in FTS)
    if config["procedural"] > 0:
        procedural_results = search(
            task_description,
            tier="semantic",
            limit=config["procedural"],
        )
        results["procedural"] = procedural_results

    # Error-solution memories
    if config["error_solutions"] > 0:
        error_results = search(
            task_description,
            tier="error-solutions",
            limit=config["error_solutions"],
        )
        results["error_solutions"] = error_results

    # Causal factors (success factors) - always included for complex depth
    if config["episodes"] or depth == "complex":
        causal_factors = get_success_factors(limit=config["semantic"])
        results["causal_factors"] = causal_factors

    db.close()
    return results
