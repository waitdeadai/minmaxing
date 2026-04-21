"""
SQLite foundation for minmaxing's 5-tier memory system.

Provides persistent storage for:
- Semantic memories (principles, patterns, knowledge)
- Error-solution pairs (known bugs and fixes)
- Causal edges (Bayesian factor-outcome relationships)
- Memory metadata (halflife, consolidation state, etc.)
"""

import os
import time
import math
import json
import uuid
import statistics
from datetime import datetime, timedelta
from typing import Optional, Any


class MemoryDB:
    """
    SQLite-backed memory database with FTS5 search and adaptive recall.

    Tier mapping:
      tier 1 (episodic) → session history (not stored here, use .taste/sessions/)
      tier 2 (semantic) → semantic table
      tier 3 (procedural) → semantic with category='pattern'
      tier 4 (error-solution) → error_solutions table
      tier 5 (causal) → causal_edges table
    """

    DEFAULT_HALFLIFE_DAYS = 30.0
    DEFAULT_CONSOLIDATION_THRESHOLD = 0.3
    DEFAULT_CAP_PER_PROJECT = 10000

    def __init__(self, db_path: str = ".minimaxing/memory.db"):
        self.db_path = db_path
        self._ensure_dir()
        self._conn = self._connect()
        self._init_pragmas()
        self._init_tables()
        self._init_fts()
        self._init_triggers()
        self._init_meta()

    # ------------------------------------------------------------------
    # Connection & initialization
    # ------------------------------------------------------------------

    def _ensure_dir(self) -> None:
        directory = os.path.dirname(self.db_path)
        if directory:
            os.makedirs(directory, exist_ok=True)

    def _connect(self):
        import sqlite3
        conn = sqlite3.connect(self.db_path, check_same_thread=False)
        conn.row_factory = sqlite3.Row
        return conn

    def _init_pragmas(self) -> None:
        self._conn.execute("PRAGMA journal_mode=WAL")
        self._conn.execute("PRAGMA cache_size=-65536")          # 64 MB page cache
        self._conn.execute("PRAGMA temp_store=MEMORY")
        self._conn.execute("PRAGMA mmap_size=268435456")        # 256 MB mmap
        self._conn.execute("PRAGMA busy_timeout=5000")          # 5 s
        self._conn.execute("PRAGMA foreign_keys=ON")
        self._conn.commit()

    def _init_tables(self) -> None:
        self._conn.executescript("""
            CREATE TABLE IF NOT EXISTS semantic (
                memory_id      TEXT    PRIMARY KEY,
                text          TEXT    NOT NULL,
                category      TEXT    NOT NULL DEFAULT '',
                confidence    REAL    NOT NULL DEFAULT 0.5,
                importance    REAL    NOT NULL DEFAULT 0.5,
                evidence_count INTEGER NOT NULL DEFAULT 0,
                success_count  INTEGER NOT NULL DEFAULT 0,
                failure_count  INTEGER NOT NULL DEFAULT 0,
                tags          TEXT    NOT NULL DEFAULT '[]',
                created_at    REAL    NOT NULL,
                project       TEXT    NOT NULL DEFAULT '',
                superseded_by TEXT    DEFAULT NULL
            );

            CREATE TABLE IF NOT EXISTS error_solutions (
                error_id         TEXT    PRIMARY KEY,
                error_pattern    TEXT    NOT NULL,
                solution         TEXT    NOT NULL,
                context          TEXT    NOT NULL DEFAULT '',
                confidence       REAL    NOT NULL DEFAULT 0.5,
                occurrences      INTEGER NOT NULL DEFAULT 0,
                project_specific INTEGER NOT NULL DEFAULT 0,
                last_seen        REAL    NOT NULL,
                created_at       REAL    NOT NULL
            );

            CREATE TABLE IF NOT EXISTS causal_edges (
                factor      TEXT    PRIMARY KEY,
                outcome     TEXT    NOT NULL,
                weight      REAL    NOT NULL DEFAULT 0.5,
                observations INTEGER NOT NULL DEFAULT 0,
                UNIQUE(factor, outcome)
            );

            CREATE TABLE IF NOT EXISTS memory_meta (
                key         TEXT    PRIMARY KEY,
                value       TEXT    NOT NULL,
                updated_at  REAL    NOT NULL
            );
        """)
        self._conn.commit()

    def _init_fts(self) -> None:
        self._conn.executescript("""
            CREATE VIRTUAL TABLE IF NOT EXISTS semantic_fts USING fts5(
                memory_id,
                text,
                category,
                tags,
                content='semantic',
                content_rowid='rowid',
                tokenize='porter unicode61'
            );

            CREATE VIRTUAL TABLE IF NOT EXISTS error_solutions_fts USING fts5(
                error_id,
                error_pattern,
                solution,
                context,
                content='error_solutions',
                content_rowid='rowid',
                tokenize='porter unicode61'
            );
        """)
        self._conn.commit()

    def _init_triggers(self) -> None:
        self._conn.executescript("""
            -- Sync semantic_fts on insert
            CREATE TRIGGER IF NOT EXISTS semantic_fts_insert
            AFTER INSERT ON semantic BEGIN
                INSERT INTO semantic_fts(rowid, memory_id, text, category, tags)
                VALUES (NEW.rowid, NEW.memory_id, NEW.text, NEW.category, NEW.tags);
            END;

            -- Sync semantic_fts on delete
            CREATE TRIGGER IF NOT EXISTS semantic_fts_delete
            AFTER DELETE ON semantic BEGIN
                INSERT INTO semantic_fts(semantic_fts, rowid, memory_id, text, category, tags)
                VALUES ('delete', OLD.rowid, OLD.memory_id, OLD.text, OLD.category, OLD.tags);
            END;

            -- Sync semantic_fts on update
            CREATE TRIGGER IF NOT EXISTS semantic_fts_update
            AFTER UPDATE ON semantic BEGIN
                INSERT INTO semantic_fts(semantic_fts, rowid, memory_id, text, category, tags)
                VALUES ('delete', OLD.rowid, OLD.memory_id, OLD.text, OLD.category, OLD.tags);
                INSERT INTO semantic_fts(rowid, memory_id, text, category, tags)
                VALUES (NEW.rowid, NEW.memory_id, NEW.text, NEW.category, NEW.tags);
            END;

            -- Sync error_solutions_fts on insert
            CREATE TRIGGER IF NOT EXISTS error_solutions_fts_insert
            AFTER INSERT ON error_solutions BEGIN
                INSERT INTO error_solutions_fts(rowid, error_id, error_pattern, solution, context)
                VALUES (NEW.rowid, NEW.error_id, NEW.error_pattern, NEW.solution, NEW.context);
            END;

            -- Sync error_solutions_fts on delete
            CREATE TRIGGER IF NOT EXISTS error_solutions_fts_delete
            AFTER DELETE ON error_solutions BEGIN
                INSERT INTO error_solutions_fts(error_solutions_fts, rowid, error_id, error_pattern, solution, context)
                VALUES ('delete', OLD.rowid, OLD.error_id, OLD.error_pattern, OLD.solution, OLD.context);
            END;

            -- Sync error_solutions_fts on update
            CREATE TRIGGER IF NOT EXISTS error_solutions_fts_update
            AFTER UPDATE ON error_solutions BEGIN
                INSERT INTO error_solutions_fts(error_solutions_fts, rowid, error_id, error_pattern, solution, context)
                VALUES ('delete', OLD.rowid, OLD.error_id, OLD.error_pattern, OLD.solution, OLD.context);
                INSERT INTO error_solutions_fts(rowid, error_id, error_pattern, solution, context)
                VALUES (NEW.rowid, NEW.error_id, NEW.error_pattern, NEW.solution, NEW.context);
            END;
        """)
        self._conn.commit()

    def _init_meta(self) -> None:
        now = time.time()
        self._conn.execute(
            "INSERT OR IGNORE INTO memory_meta (key, value, updated_at) VALUES (?, ?, ?)",
            ("halflife_days", str(self.DEFAULT_HALFLIFE_DAYS), now),
        )
        self._conn.execute(
            "INSERT OR IGNORE INTO memory_meta (key, value, updated_at) VALUES (?, ?, ?)",
            ("consolidation_threshold", str(self.DEFAULT_CONSOLIDATION_THRESHOLD), now),
        )
        self._conn.execute(
            "INSERT OR IGNORE INTO memory_meta (key, value, updated_at) VALUES (?, ?, ?)",
            ("last_consolidation", "0", now),
        )
        self._conn.execute(
            "INSERT OR IGNORE INTO memory_meta (key, value, updated_at) VALUES (?, ?, ?)",
            ("last_decay", "0", now),
        )
        self._conn.commit()

    # ------------------------------------------------------------------
    # Public API
    # ------------------------------------------------------------------

    def add_semantic(
        self,
        text: str,
        category: str,
        tags: list[str],
        confidence: float = 0.5,
        project: str = "",
    ) -> str:
        """
        Add a semantic memory.

        Returns the memory_id.
        """
        memory_id = str(uuid.uuid4())
        now = time.time()
        tags_json = json.dumps(tags)

        self._conn.execute(
            """
            INSERT INTO semantic
                (memory_id, text, category, confidence, tags, created_at, project)
            VALUES (?, ?, ?, ?, ?, ?, ?)
            """,
            (memory_id, text, category, confidence, tags_json, now, project),
        )
        self._conn.commit()
        return memory_id

    def add_error_solution(
        self,
        error_pattern: str,
        solution: str,
        context: str = "",
        project: str = "",
    ) -> str:
        """
        Add or update an error-solution pair.

        If the same error_pattern already exists (for the same project), updates
        the occurrence count and last_seen timestamp instead of creating a new
        entry.

        Returns the error_id.
        """
        now = time.time()

        existing = self._conn.execute(
            """
            SELECT error_id, occurrences FROM error_solutions
            WHERE error_pattern = ? AND project_specific = ?
            """,
            (error_pattern, 1 if project else 0),
        ).fetchone()

        if existing:
            self._conn.execute(
                """
                UPDATE error_solutions
                SET occurrences = occurrences + 1, last_seen = ?, solution = ?
                WHERE error_id = ?
                """,
                (now, solution, existing["error_id"]),
            )
            self._conn.commit()
            return existing["error_id"]

        error_id = str(uuid.uuid4())
        self._conn.execute(
            """
            INSERT INTO error_solutions
                (error_id, error_pattern, solution, context, occurrences,
                 project_specific, last_seen, created_at)
            VALUES (?, ?, ?, ?, 1, ?, ?, ?)
            """,
            (
                error_id,
                error_pattern,
                solution,
                context,
                1 if project else 0,
                now,
                now,
            ),
        )
        self._conn.commit()
        return error_id

    def add_causal_edge(
        self,
        factor: str,
        outcome: str,
        weight: float = 0.5,
    ) -> None:
        """
        Add or update a causal edge with Bayesian weight update.

        If the edge already exists, updates weight using a running
        Bayesian estimate (success/failure observations → posterior mean).
        """
        existing = self._conn.execute(
            "SELECT weight, observations FROM causal_edges WHERE factor = ? AND outcome = ?",
            (factor, outcome),
        ).fetchone()

        if existing:
            # Bayesian update: weighted average of prior and new evidence
            n = existing["observations"]
            w = existing["weight"]
            # Increment observation count and blend weights
            new_weight = (w * n + weight) / (n + 1)
            self._conn.execute(
                """
                UPDATE causal_edges
                SET weight = ?, observations = observations + 1
                WHERE factor = ? AND outcome = ?
                """,
                (new_weight, factor, outcome),
            )
        else:
            self._conn.execute(
                """
                INSERT INTO causal_edges (factor, outcome, weight, observations)
                VALUES (?, ?, ?, 1)
                """,
                (factor, outcome, weight),
            )
        self._conn.commit()

    def get_stats(self) -> dict[str, Any]:
        """Return counts for each table."""
        stats = {}

        stats["semantic"] = self._conn.execute(
            "SELECT COUNT(*) as c FROM semantic"
        ).fetchone()["c"]

        stats["error_solutions"] = self._conn.execute(
            "SELECT COUNT(*) as c FROM error_solutions"
        ).fetchone()["c"]

        stats["causal_edges"] = self._conn.execute(
            "SELECT COUNT(*) as c FROM causal_edges"
        ).fetchone()["c"]

        stats["projects"] = self._conn.execute(
            "SELECT COUNT(DISTINCT project) as c FROM semantic"
        ).fetchone()["c"]

        halflife_row = self._conn.execute(
            "SELECT value FROM memory_meta WHERE key = 'halflife_days'"
        ).fetchone()
        stats["halflife_days"] = (
            float(halflife_row["value"]) if halflife_row else self.DEFAULT_HALFLIFE_DAYS
        )

        return stats

    def recall(
        self,
        query: str,
        tier: int,
        limit: int = 10,
    ) -> list[dict[str, Any]]:
        """
        Adaptive-depth recall for a given query and memory tier.

        tier mapping:
          1 → episodic (session history, not in this DB; returns empty)
          2 → semantic (importance-weighted)
          3 → procedural (category='pattern', importance-weighted)
          4 → error_solutions (recency-weighted)
          5 → causal_edges (weight-ordered)

        Returns a list of matching rows as dicts.
        """
        if tier == 1:
            # Episodic tier lives in .taste/sessions/, not here
            return []
        elif tier == 2:
            return self._recall_semantic(query, limit, category=None)
        elif tier == 3:
            return self._recall_semantic(query, limit, category="pattern")
        elif tier == 4:
            return self._recall_errors(query, limit)
        elif tier == 5:
            return self._recall_causal(query, limit)
        else:
            return []

    def _recall_semantic(
        self,
        query: str,
        limit: int,
        category: Optional[str] = None,
    ) -> list[dict[str, Any]]:
        now = time.time()
        halflife_seconds = self._get_halflife_seconds()

        base_sql = """
            SELECT memory_id, text, category, confidence, importance,
                   evidence_count, success_count, failure_count, tags,
                   created_at, project,
                   (importance * POW(0.5, ({} - created_at) / ?)) AS effective_score
            FROM semantic
            WHERE superseded_by IS NULL
        """.format(now)

        params: list[Any] = [halflife_seconds]

        if category is not None:
            base_sql += " AND category = ?"
            params.append(category)

        if query:
            base_sql += " AND (text LIKE ? OR tags LIKE ?)"
            params.extend([f"%{query}%", f"%{query}%"])

        base_sql += " ORDER BY effective_score DESC, created_at DESC LIMIT ?"
        params.append(limit)

        rows = self._conn.execute(base_sql, params).fetchall()
        return [dict(r) for r in rows]

    def _recall_errors(
        self,
        query: str,
        limit: int,
    ) -> list[dict[str, Any]]:
        now = time.time()
        halflife_seconds = self._get_halflife_seconds()

        params: list[Any] = [halflife_seconds]

        sql = """
            SELECT error_id, error_pattern, solution, context,
                   confidence, occurrences, project_specific,
                   last_seen, created_at,
                   (confidence * POW(0.5, ({} - last_seen) / ?)) AS effective_score
            FROM error_solutions
            WHERE 1=1
        """.format(now)

        if query:
            sql += " AND (error_pattern LIKE ? OR solution LIKE ?)"
            params.extend([f"%{query}%", f"%{query}%"])

        sql += " ORDER BY effective_score DESC, last_seen DESC LIMIT ?"
        params.append(limit)

        rows = self._conn.execute(sql, params).fetchall()
        return [dict(r) for r in rows]

    def _recall_causal(
        self,
        query: str,
        limit: int,
    ) -> list[dict[str, Any]]:
        params: list[Any] = []
        sql = "SELECT factor, outcome, weight, observations FROM causal_edges WHERE 1=1"

        if query:
            sql += " AND (factor LIKE ? OR outcome LIKE ?)"
            params.extend([f"%{query}%", f"%{query}%"])

        sql += " ORDER BY weight DESC, observations DESC LIMIT ?"
        params.append(limit)

        rows = self._conn.execute(sql, params).fetchall()
        return [dict(r) for r in rows]

    def search(
        self,
        query: str,
        tier: int,
        limit: int = 10,
    ) -> list[dict[str, Any]]:
        """
        FTS5 bm25-ranked full-text search across semantic and error_solutions.

        tier mapping:
          1 → episodic (not in DB; returns empty)
          2 → semantic_fts
          3 → semantic_fts filtered to category='pattern'
          4 → error_solutions_fts
          5 → causal_edges (uses LIKE search, not FTS)
        """
        if not query:
            return self.recall(query="", tier=tier, limit=limit)

        if tier == 1:
            return []
        elif tier == 2:
            return self._search_semantic_fts(query, limit, category=None)
        elif tier == 3:
            return self._search_semantic_fts(query, limit, category="pattern")
        elif tier == 4:
            return self._search_error_fts(query, limit)
        elif tier == 5:
            # Causal edges use keyword search, not FTS
            return self._recall_causal(query, limit)
        else:
            return []

    def _search_semantic_fts(
        self,
        query: str,
        limit: int,
        category: Optional[str] = None,
    ) -> list[dict[str, Any]]:
        """
        FTS5 search over semantic_fts with bm25 ranking,
        then enrich with live confidence/importance scores.
        """
        now = time.time()
        halflife_seconds = self._get_halflife_seconds()

        # Base FTS query
        fts_sql = """
            SELECT memory_id,
                   bm25(semantic_fts, 3.0, 5.0, 1.0) AS rank
            FROM semantic_fts
            WHERE semantic_fts MATCH ?
            ORDER BY rank
            LIMIT ?
        """

        fts_rows = self._conn.execute(fts_sql, (query, limit * 3)).fetchall()
        if not fts_rows:
            return []

        memory_ids = [r["memory_id"] for r in fts_rows]

        placeholders = ",".join(["?"] * len(memory_ids))
        base_sql = f"""
            SELECT s.memory_id, s.text, s.category, s.confidence, s.importance,
                   s.evidence_count, s.success_count, s.failure_count, s.tags,
                   s.created_at, s.project,
                   (s.importance * POW(0.5, ({now} - s.created_at) / ?)) AS effective_score
            FROM semantic s
            WHERE s.memory_id IN ({placeholders})
        """

        params: list[Any] = [halflife_seconds] + memory_ids

        if category is not None:
            base_sql += " AND s.category = ?"
            params.append(category)

        base_sql += " ORDER BY effective_score DESC LIMIT ?"
        params.append(limit)

        rows = self._conn.execute(base_sql, params).fetchall()
        return [dict(r) for r in rows]

    def _search_error_fts(
        self,
        query: str,
        limit: int,
    ) -> list[dict[str, Any]]:
        now = time.time()
        halflife_seconds = self._get_halflife_seconds()

        fts_sql = """
            SELECT error_id,
                   bm25(error_solutions_fts, 3.0, 5.0, 1.0) AS rank
            FROM error_solutions_fts
            WHERE error_solutions_fts MATCH ?
            ORDER BY rank
            LIMIT ?
        """

        fts_rows = self._conn.execute(fts_sql, (query, limit * 3)).fetchall()
        if not fts_rows:
            return []

        error_ids = [r["error_id"] for r in fts_rows]

        placeholders = ",".join(["?"] * len(error_ids))
        sql = f"""
            SELECT e.error_id, e.error_pattern, e.solution, e.context,
                   e.confidence, e.occurrences, e.project_specific,
                   e.last_seen, e.created_at,
                   (e.confidence * POW(0.5, ({now} - e.last_seen) / ?)) AS effective_score
            FROM error_solutions e
            WHERE e.error_id IN ({placeholders})
            ORDER BY effective_score DESC
            LIMIT ?
        """

        params: list[Any] = [halflife_seconds] + error_ids + [limit]
        rows = self._conn.execute(sql, params).fetchall()
        return [dict(r) for r in rows]

    def consolidate(self) -> dict[str, int]:
        """
        Memory consolidation:
          1. Merge near-duplicate semantic memories (Jaccard similarity > 0.8)
          2. Prune semantic entries with confidence < threshold
          3. Cap per-project semantic entries at cap limit (evict oldest)

        Returns a dict with counts of merged/pruned/evicted entries.
        """
        threshold = self._get_consolidation_threshold()
        cap = self.DEFAULT_CAP_PER_PROJECT
        now = time.time()
        halflife_seconds = self._get_halflife_seconds()
        stats: dict[str, int] = {"merged": 0, "pruned": 0, "evicted": 0}

        # --- Step 1: Prune low-confidence semantic entries ---
        last_consol = self._get_last_consolidation()
        decayed_threshold = threshold * (0.5 ** ((now - last_consol) / halflife_seconds))
        decayed_threshold = max(decayed_threshold, 0.1)  # floor at 0.1

        prune_result = self._conn.execute(
            """
            DELETE FROM semantic
            WHERE confidence < ? AND superseded_by IS NULL
            """,
            (decayed_threshold,),
        )
        stats["pruned"] = prune_result.rowcount

        # --- Step 2: Merge near-duplicate semantic entries ---
        # Find candidate pairs using simple token overlap
        candidates = self._conn.execute(
            """
            SELECT s1.memory_id AS id1, s2.memory_id AS id2
            FROM semantic s1
            JOIN semantic s2
              ON s1.memory_id < s2.memory_id
             AND s1.superseded_by IS NULL
             AND s2.superseded_by IS NULL
             AND s1.category = s2.category
            WHERE (
                SELECT COUNT(*) FROM (
                    SELECT value FROM json_each(s1.tags)
                    INTERSECT
                    SELECT value FROM json_each(s2.tags)
                )
            ) * 1.0 / (
                SELECT COUNT(*) FROM (
                    SELECT value FROM json_each(s1.tags)
                    UNION ALL
                    SELECT value FROM json_each(s2.tags)
                )
            ) > 0.8
            """,
        ).fetchall()

        merged_ids: set[str] = set()
        for row in candidates:
            id1, id2 = row["id1"], row["id2"]
            if id1 in merged_ids or id2 in merged_ids:
                continue

            # Keep the newer, higher-confidence entry
            r1 = self._conn.execute(
                "SELECT created_at, confidence FROM semantic WHERE memory_id = ?", (id1,)
            ).fetchone()
            r2 = self._conn.execute(
                "SELECT created_at, confidence FROM semantic WHERE memory_id = ?", (id2,)
            ).fetchone()

            keep_id, superseded_id = (id1, id2) if r1["confidence"] >= r2["confidence"] else (id2, id1)

            self._conn.execute(
                "UPDATE semantic SET superseded_by = ? WHERE memory_id = ?",
                (keep_id, superseded_id),
            )
            merged_ids.add(superseded_id)
            stats["merged"] += 1

        # --- Step 3: Cap per-project semantic entries ---
        projects = self._conn.execute(
            "SELECT DISTINCT project FROM semantic WHERE superseded_by IS NULL"
        ).fetchall()

        for proj_row in projects:
            project = proj_row["project"]
            count_row = self._conn.execute(
                """
                SELECT COUNT(*) as c FROM semantic
                WHERE project = ? AND superseded_by IS NULL
                """,
                (project,),
            ).fetchone()

            if count_row["c"] > cap:
                excess = count_row["c"] - cap
                # Evict oldest entries
                self._conn.execute(
                    """
                    DELETE FROM semantic
                    WHERE memory_id IN (
                        SELECT memory_id FROM semantic
                        WHERE project = ? AND superseded_by IS NULL
                        ORDER BY created_at ASC
                        LIMIT ?
                    )
                    """,
                    (project, excess),
                )
                stats["evicted"] += excess

        self._conn.execute(
            "INSERT OR REPLACE INTO memory_meta (key, value, updated_at) VALUES (?, ?, ?)",
            ("last_consolidation", str(now), now),
        )
        self._conn.commit()

        return stats

    def decay(self) -> dict[str, int]:
        """
        Apply exponential decay to all confidence and importance scores.

        Each memory's confidence and importance are multiplied by
        0.5^(elapsed_halflives), where halflife is configurable via
        memory_meta['halflife_days'].

        Returns counts of updated rows per table.
        """
        now = time.time()
        halflife_seconds = self._get_halflife_seconds()
        elapsed = now - self._get_last_decay()

        if elapsed < halflife_seconds * 0.01:
            # Skip if less than 1% of a halflife has passed
            return {"semantic": 0, "error_solutions": 0, "causal_edges": 0}

        decay_factor = 0.5 ** (elapsed / halflife_seconds)

        # Decay semantic confidence and importance
        sem_result = self._conn.execute(
            """
            UPDATE semantic
            SET confidence = MAX(0.01, confidence * ?),
                importance  = MAX(0.01, importance  * ?)
            WHERE superseded_by IS NULL
            """,
            (decay_factor, decay_factor),
        )

        # Decay error_solutions confidence
        err_result = self._conn.execute(
            """
            UPDATE error_solutions
            SET confidence = MAX(0.01, confidence * ?)
            """,
            (decay_factor,),
        )

        # Decay causal edge weights
        caus_result = self._conn.execute(
            """
            UPDATE causal_edges
            SET weight = MAX(0.01, weight * ?)
            """,
            (decay_factor,),
        )

        self._conn.execute(
            "INSERT OR REPLACE INTO memory_meta (key, value, updated_at) VALUES (?, ?, ?)",
            ("last_decay", str(now), now),
        )
        self._conn.commit()

        return {
            "semantic": sem_result.rowcount,
            "error_solutions": err_result.rowcount,
            "causal_edges": caus_result.rowcount,
        }

    # ------------------------------------------------------------------
    # Helper methods
    # ------------------------------------------------------------------

    def _get_halflife_seconds(self) -> float:
        row = self._conn.execute(
            "SELECT value FROM memory_meta WHERE key = 'halflife_days'"
        ).fetchone()
        days = float(row["value"]) if row else self.DEFAULT_HALFLIFE_DAYS
        return days * 86400.0

    def _get_consolidation_threshold(self) -> float:
        row = self._conn.execute(
            "SELECT value FROM memory_meta WHERE key = 'consolidation_threshold'"
        ).fetchone()
        return float(row["value"]) if row else self.DEFAULT_CONSOLIDATION_THRESHOLD

    def _get_last_consolidation(self) -> float:
        row = self._conn.execute(
            "SELECT value FROM memory_meta WHERE key = 'last_consolidation'"
        ).fetchone()
        return float(row["value"]) if row else 0.0

    def _get_last_decay(self) -> float:
        row = self._conn.execute(
            "SELECT value FROM memory_meta WHERE key = 'last_decay'"
        ).fetchone()
        return float(row["value"]) if row else 0.0

    def close(self) -> None:
        """Close the database connection."""
        self._conn.close()

    def __enter__(self) -> "MemoryDB":
        return self

    def __exit__(self, *args: Any) -> None:
        self.close()
