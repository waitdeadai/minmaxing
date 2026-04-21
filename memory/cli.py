"""CLI wrapper for minmaxing memory system.

Usage:
    python -m memory.cli <command> [args]

Commands:
    search <query> [--tier semantic|error-solutions] [--limit 10]
    recall <task_description> [--depth simple|medium|complex]
    stats
    causal-factors [--outcome success|failure] [--limit 5]
"""

import argparse
import sys
from pathlib import Path

from memory.search import search as memory_search
from memory.recall import recall as memory_recall
from memory.causal import get_success_factors, get_failure_factors
from memory.sqlite_db import MemoryDB


def cmd_search(args: argparse.Namespace) -> int:
    """Execute the search command.

    Args:
        args: Parsed command-line arguments

    Returns:
        Exit code (0 for success, non-zero for error)
    """
    try:
        all_results = []
        tiers_to_search = [args.tier] if args.tier else ["semantic", "error-solutions"]

        for tier in tiers_to_search:
            results = memory_search(
                query=args.query,
                tier=tier,
                limit=args.limit,
            )
            for r in results:
                r["tier"] = tier
            all_results.extend(results)

        if not all_results:
            print("No results found.")
            return 0

        print(f"=== Search Results for: {args.query} ===")
        print(f"Tier: {args.tier or 'all'}")
        print(f"Found: {len(all_results)} result(s)")
        print()

        for i, result in enumerate(all_results, 1):
            confidence = result.get("confidence", 0)
            rank = result.get("rank", 0)
            memory_id = result.get("memory_id", "N/A")
            text = result.get("text", "")
            tags = result.get("tags", "")
            tier = result.get("tier", "")

            print(f"[{i}] Memory ID: {memory_id} ({tier})")
            print(f"    Confidence: {confidence:.2f}")
            print(f"    Rank: {rank:.2f}")
            if tags:
                print(f"    Tags: {tags}")
            # Show first 200 chars of text
            preview = text[:200] + "..." if len(text) > 200 else text
            print(f"    Content: {preview}")
            print()

        return 0

    except ValueError as e:
        print(f"Error: {e}", file=sys.stderr)
        return 1
    except Exception as e:
        print(f"Search failed: {e}", file=sys.stderr)
        return 1


def cmd_recall(args: argparse.Namespace) -> int:
    """Execute the recall command.

    Args:
        args: Parsed command-line arguments

    Returns:
        Exit code (0 for success, non-zero for error)
    """
    try:
        results = memory_recall(
            task_description=args.task_description,
            depth=args.depth,
        )

        print(f"=== Recall Results for: {args.task_description} ===")
        print(f"Depth: {args.depth}")
        print()

        # Process semantic memories
        semantic = results.get("semantic", [])
        if semantic:
            print(f"--- Semantic Memories ({len(semantic)}) ---")
            for i, item in enumerate(semantic, 1):
                text = item.get("text", item.get("content", ""))
                preview = text[:200] + "..." if len(text) > 200 else text
                confidence = item.get("confidence", 0)
                print(f"  [{i}] Confidence: {confidence:.2f}")
                print(f"      {preview}")
                print()
        else:
            print("--- Semantic Memories (0) ---")
            print("  (none found)")
            print()

        # Process procedural memories
        procedural = results.get("procedural", [])
        if procedural:
            print(f"--- Procedural Memories ({len(procedural)}) ---")
            for i, item in enumerate(procedural, 1):
                text = item.get("text", item.get("content", ""))
                preview = text[:200] + "..." if len(text) > 200 else text
                confidence = item.get("confidence", 0)
                print(f"  [{i}] Confidence: {confidence:.2f}")
                print(f"      {preview}")
                print()
        else:
            print("--- Procedural Memories (0) ---")
            print("  (none found)")
            print()

        # Process error-solution memories
        error_solutions = results.get("error_solutions", [])
        if error_solutions:
            print(f"--- Error Solutions ({len(error_solutions)}) ---")
            for i, item in enumerate(error_solutions, 1):
                text = item.get("text", item.get("content", ""))
                preview = text[:200] + "..." if len(text) > 200 else text
                confidence = item.get("confidence", 0)
                print(f"  [{i}] Confidence: {confidence:.2f}")
                print(f"      {preview}")
                print()
        else:
            print("--- Error Solutions (0) ---")
            print("  (none found)")
            print()

        # Process causal factors
        causal_factors = results.get("causal_factors", [])
        if causal_factors:
            print(f"--- Causal Factors ({len(causal_factors)}) ---")
            for i, factor in enumerate(causal_factors, 1):
                print(f"  [{i}] {factor}")
            print()

        return 0

    except Exception as e:
        print(f"Recall failed: {e}", file=sys.stderr)
        return 1


def cmd_stats(args: argparse.Namespace) -> int:
    """Execute the stats command.

    Args:
        args: Parsed command-line arguments

    Returns:
        Exit code (0 for success, non-zero for error)
    """
    try:
        db = MemoryDB()

        print("=== Memory System Stats ===")
        print()

        # Get stats from MemoryDB
        stats = db.get_stats()

        print("  SQLite Storage:")
        print(f"    semantic: {stats.get('semantic', 0)} entries")
        print(f"    error_solutions: {stats.get('error_solutions', 0)} entries")
        print(f"    causal_edges: {stats.get('causal_edges', 0)} entries")

        total = stats.get('semantic', 0) + stats.get('error_solutions', 0)
        print(f"    projects: {stats.get('projects', 0)}")
        print(f"    halflife_days: {stats.get('halflife_days', 30)}")

        # Memory file counts (file-based storage)
        print()
        print("  File-Based Storage:")

        memory_dir = Path("obsidian/Memory")
        taste_dir = Path(".taste")

        if memory_dir.exists():
            for folder, label in [
                ("Decisions", "decisions"),
                ("Patterns", "patterns"),
                ("Errors", "error-solutions"),
                ("Stories", "stories"),
            ]:
                folder_path = memory_dir / folder
                if folder_path.exists():
                    count = len(list(folder_path.glob("*.md")))
                    print(f"    {label}: {count} files")
        else:
            print("    (memory directory not found)")

        # Session files
        sessions_path = taste_dir / "sessions"
        if sessions_path.exists():
            jsonl_files = list(sessions_path.glob("*.jsonl"))
            total_lines = 0
            for jsonl_file in jsonl_files:
                try:
                    with open(jsonl_file) as f:
                        total_lines += sum(1 for _ in f)
                except Exception:
                    pass
            print(f"    episodic: {total_lines} entries across {len(jsonl_files)} session(s)")
        else:
            print("    episodic: 0 entries")

        print()
        print(f"  Total memories: {total}")
        print()

        db.close()
        return 0

    except Exception as e:
        print(f"Stats failed: {e}", file=sys.stderr)
        return 1


def cmd_causal_factors(args: argparse.Namespace) -> int:
    """Execute the causal-factors command.

    Args:
        args: Parsed command-line arguments

    Returns:
        Exit code (0 for success, non-zero for error)
    """
    try:
        if args.outcome == "success":
            factors = get_success_factors(limit=args.limit)
            print(f"=== Success Factors (top {args.limit}) ===")
        else:
            factors = get_failure_factors(limit=args.limit)
            print(f"=== Failure Factors (top {args.limit}) ===")

        if not factors:
            print("No factors recorded yet.")
            return 0

        print()
        for i, factor in enumerate(factors, 1):
            factor_name = factor.get("factor", "unknown")
            weight = factor.get("weight", 0)
            observations = factor.get("observations", 0)

            # Interpret weight
            if args.outcome == "success":
                interpretation = "strongly correlates with success" if weight > 0.5 else "correlates with success" if weight > 0 else "mixed"
            else:
                interpretation = "strongly correlates with failure" if weight < -0.5 else "correlates with failure" if weight < 0 else "mixed"

            print(f"[{i}] {factor_name}")
            print(f"    Weight: {weight:.3f} ({interpretation})")
            print(f"    Observations: {observations}")
            print()

        return 0

    except Exception as e:
        print(f"Causal analysis failed: {e}", file=sys.stderr)
        return 1


def cmd_add(args: argparse.Namespace) -> int:
    """Execute the add command.

    Args:
        args: Parsed command-line arguments

    Returns:
        Exit code (0 for success, non-zero for error)
    """
    try:
        db = MemoryDB()

        if args.tier == "semantic":
            memory_id = db.add_semantic(
                text=args.content,
                category="general",
                tags=args.tags.split(",") if args.tags else [],
                confidence=0.5,
            )
            print(f"Added semantic memory: {memory_id}")
        elif args.tier == "error-solutions":
            memory_id = db.add_error_solution(
                error_pattern=args.content,
                solution=args.solution or "",
                context="",
            )
            print(f"Added error-solution memory: {memory_id}")
        elif args.tier == "procedural":
            # Procedural is stored as semantic with category='pattern'
            memory_id = db.add_semantic(
                text=args.content,
                category="pattern",
                tags=args.tags.split(",") if args.tags else [],
                confidence=0.5,
            )
            print(f"Added procedural memory: {memory_id}")
        elif args.tier == "graph":
            from memory.causal import record_outcome
            outcome = args.solution if args.solution else "unknown"
            record_outcome([args.content], outcome)
            memory_id = f"graph-{args.content[:20]}"
            print(f"Added graph memory: {memory_id}")
        else:
            print(f"Unknown tier: {args.tier}")
            return 1

        db.close()
        return 0

    except Exception as e:
        print(f"Add failed: {e}", file=sys.stderr)
        return 1


def main() -> int:
    """Main entry point for the memory CLI.

    Returns:
        Exit code from the executed command
    """
    parser = argparse.ArgumentParser(
        prog="python -m memory.cli",
        description="minmaxing memory system CLI",
    )

    subparsers = parser.add_subparsers(dest="command", help="Available commands")

    # Search command
    search_parser = subparsers.add_parser(
        "search",
        help="Search memory system",
    )
    search_parser.add_argument(
        "query",
        help="Search query string",
    )
    search_parser.add_argument(
        "--tier",
        choices=["semantic", "error-solutions"],
        default=None,
        help="Memory tier to search (default: all tiers)",
    )
    search_parser.add_argument(
        "--limit",
        type=int,
        default=10,
        help="Maximum number of results (default: 10)",
    )

    # Recall command
    recall_parser = subparsers.add_parser(
        "recall",
        help="Recall memories related to a task",
    )
    recall_parser.add_argument(
        "task_description",
        help="Description of the task to recall memories for",
    )
    recall_parser.add_argument(
        "--depth",
        choices=["simple", "medium", "complex"],
        default="medium",
        help="Recall depth (default: medium)",
    )

    # Stats command
    subparsers.add_parser(
        "stats",
        help="Show memory system statistics",
    )

    # Causal-factors command
    causal_parser = subparsers.add_parser(
        "causal-factors",
        help="Analyze causal factors from memory system",
    )
    causal_parser.add_argument(
        "--outcome",
        choices=["success", "failure"],
        default="success",
        help="Type of outcome to analyze (default: success)",
    )
    causal_parser.add_argument(
        "--limit",
        type=int,
        default=5,
        help="Maximum number of factors to return (default: 5)",
    )

    # Add command
    add_parser = subparsers.add_parser(
        "add",
        help="Add a memory entry",
    )
    add_parser.add_argument(
        "tier",
        choices=["semantic", "procedural", "error-solutions", "graph"],
        help="Memory tier",
    )
    add_parser.add_argument(
        "content",
        help="Memory content (for error-solutions: error pattern)",
    )
    add_parser.add_argument(
        "solution",
        nargs="?",
        default=None,
        help="Solution (required for error-solutions tier)",
    )
    add_parser.add_argument(
        "--tags",
        default="",
        help="Comma-separated tags",
    )

    args = parser.parse_args()

    if args.command is None:
        parser.print_help()
        return 1

    # Dispatch to command handler
    if args.command == "search":
        return cmd_search(args)
    elif args.command == "recall":
        return cmd_recall(args)
    elif args.command == "stats":
        return cmd_stats(args)
    elif args.command == "causal-factors":
        return cmd_causal_factors(args)
    elif args.command == "add":
        return cmd_add(args)
    else:
        parser.print_help()
        return 1


if __name__ == "__main__":
    sys.exit(main())
