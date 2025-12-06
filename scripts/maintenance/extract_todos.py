#!/usr/bin/env python3
"""Extract and categorize task markers for GitHub issue creation.

Usage:  # pragma: allowlist todo
    python scripts/maintenance/extract_todos.py \\
        [--output OUTPUT_FILE] [--format json|markdown]
"""  # pragma: allowlist todo

import argparse
import json
import re
import sys
from collections import defaultdict
from dataclasses import asdict, dataclass
from pathlib import Path


@dataclass
class TodoItem:  # pragma: allowlist todo
    """Represents a single TODO/FIXME item."""  # pragma: allowlist todo

    file_path: str
    line_number: int
    todo_type: str  # TODO or FIXME  # pragma: allowlist todo
    content: str
    context: str  # Surrounding lines for context
    category: str  # Code, Config, Documentation
    priority: str  # P0, P1, P2
    area: str  # Component/area tag


def categorize_file(file_path: str) -> str:
    """Categorize file by type."""
    if file_path.startswith("docs/"):
        return "documentation"
    elif file_path.startswith("scripts/") and file_path.endswith(".py"):
        return "code"
    elif file_path.startswith(("conf/", "env/")) or file_path.endswith((".yml", ".yaml")):
        return "configuration"
    elif file_path.endswith((".py", ".js", ".ts", ".go")):
        return "code"
    else:
        return "other"


def determine_priority(content: str, file_path: str) -> str:
    """Determine priority based on content and context."""
    content_lower = content.lower()

    # P0: Critical issues
    if any(word in content_lower for word in ["critical", "urgent", "security", "breaking"]):
        return "P0"

    # P1: Important but not critical
    if any(
        word in content_lower for word in ["important", "should", "must", "required", "blocker"]
    ):
        return "P1"

    # P0/P1: Security or CI/CD related
    if "security" in file_path or ".github/workflows" in file_path:
        return "P0"

    # P2: Nice to have
    return "P2"


def determine_area(file_path: str, content: str) -> str:
    """Determine area/component tag."""
    if "docs/" in file_path:
        if "audit" in file_path:
            return "audit"
        elif "development" in file_path:
            return "devx"
        elif "security" in file_path:
            return "security"
        return "documentation"

    if "scripts/" in file_path:
        if "infrastructure" in file_path:
            return "infrastructure"
        elif "automation" in file_path:
            return "automation"
        elif "security" in file_path:
            return "security"
        return "scripts"

    if ".github/" in file_path:
        return "ci-cd"

    if "conf/" in file_path:
        return "configuration"

    return "general"


def is_real_todo(line: str, file_path: str) -> bool:  # pragma: allowlist todo
    """Determine if this is a real TODO/FIXME or just a mention."""  # pragma: allowlist todo
    line_lower = line.lower()

    # Skip documentation about TODO/FIXME  # pragma: allowlist todo
    false_positives = [  # pragma: allowlist todo
        "todo/fixme",  # pragma: allowlist todo
        "todo or fixme",  # pragma: allowlist todo
        "todo` in",  # pragma: allowlist todo
        "fixme` in",  # pragma: allowlist todo
        "todo markers",  # pragma: allowlist todo
        "fixme markers",  # pragma: allowlist todo
        "zero todo",  # pragma: allowlist todo
        "no todo",  # pragma: allowlist todo
        "todo/fixme comments",  # pragma: allowlist todo
        "check for todo",  # pragma: allowlist todo
        "check-todo",  # pragma: allowlist todo
        "allowlist todo",  # pragma: allowlist todo
        "pragma: allowlist",
        "# todo:",  # Section headers  # pragma: allowlist todo
        "## todo",  # pragma: allowlist todo
        "### todo",  # pragma: allowlist todo
    ]

    for pattern in false_positives:
        if pattern in line_lower:
            return False

    # Skip if it's in an audit/report file
    if any(
        keyword in file_path.lower()
        for keyword in ["audit", "report", "summary", "progress", "session", "completion"]
    ):
        return False

    # Skip table rows or bullet points that just mention TODO  # pragma: allowlist todo
    # Return negated condition directly
    return not re.match(r"^\s*[\|\-\*]\s*.*TODO.*\|", line, re.IGNORECASE)  # pragma: allowlist todo


def extract_todos(root_dir: Path) -> list[TodoItem]:  # pragma: allowlist todo
    """Extract all TODO/FIXME items from the repository."""  # pragma: allowlist todo
    todos: list[TodoItem] = []  # pragma: allowlist todo
    todo_pattern = re.compile(r"(TODO|FIXME)[\s:]*(.+)$", re.IGNORECASE)  # pragma: allowlist todo

    # Directories to skip
    skip_dirs = {".venv", "node_modules", "site", ".git", "__pycache__", "coverage"}

    # File extensions to process
    valid_extensions = {".py", ".js", ".ts", ".go", ".yml", ".yaml", ".md", ".sh"}

    for file_path in root_dir.rglob("*"):
        # Skip directories
        if file_path.is_dir():
            continue

        # Skip excluded directories
        if any(skip in file_path.parts for skip in skip_dirs):
            continue

        # Skip non-text files
        if file_path.suffix not in valid_extensions:
            continue

        try:
            relative_path = str(file_path.relative_to(root_dir))

            with open(file_path, encoding="utf-8") as f:
                lines = f.readlines()

            for line_num, line in enumerate(lines, 1):
                match = todo_pattern.search(line)  # pragma: allowlist todo
                if match and is_real_todo(line, relative_path):  # pragma: allowlist todo
                    todo_type = match.group(1).upper()
                    content = match.group(2).strip()

                    # Get context (3 lines before and after)
                    context_start = max(0, line_num - 4)
                    context_end = min(len(lines), line_num + 3)
                    context = "".join(lines[context_start:context_end])
                    category = categorize_file(relative_path)
                    priority = determine_priority(content, relative_path)
                    area = determine_area(relative_path, content)

                    todos.append(  # pragma: allowlist todo
                        TodoItem(  # pragma: allowlist todo
                            file_path=relative_path,
                            line_number=line_num,
                            todo_type=todo_type,  # pragma: allowlist todo
                            content=content,
                            context=context,
                            category=category,
                            priority=priority,
                            area=area,
                        )
                    )

        except (UnicodeDecodeError, PermissionError):
            continue

    return todos


def generate_markdown_report(todos: list[TodoItem]) -> str:  # pragma: allowlist todo
    """Generate markdown report grouped by category and priority."""  # pragma: allowlist todo
    report = ["# TODO/FIXME Analysis Report\n"]  # pragma: allowlist todo
    report.append(f"**Total Items**: {len(todos)}\n")

    # Group by category
    by_category: dict[str, list[TodoItem]] = defaultdict(list)  # pragma: allowlist todo
    for todo in todos:  # pragma: allowlist todo
        by_category[todo.category].append(todo)  # pragma: allowlist todo

    report.append("## Summary by Category\n")
    for category, items in sorted(by_category.items()):
        report.append(f"- **{category.capitalize()}**: {len(items)} items")

    # Group by priority
    by_priority: dict[str, list[TodoItem]] = defaultdict(list)  # pragma: allowlist todo
    for todo in todos:  # pragma: allowlist todo
        by_priority[todo.priority].append(todo)  # pragma: allowlist todo

    report.append("\n## Summary by Priority\n")
    for priority in ["P0", "P1", "P2"]:
        count = len(by_priority[priority])
        report.append(f"- **{priority}**: {count} items")

    # Detailed breakdown
    report.append("\n## Detailed Breakdown\n")

    for priority in ["P0", "P1", "P2"]:
        items = by_priority[priority]
        if not items:
            continue

        report.append(f"\n### {priority} Priority ({len(items)} items)\n")

        # Group by area within priority
        by_area: dict[str, list[TodoItem]] = defaultdict(list)
        for item in items:
            by_area[item.area].append(item)

        for area, area_items in sorted(by_area.items()):
            report.append(f"\n#### {area.upper()} ({len(area_items)} items)\n")

            for item in area_items[:10]:  # Limit to 10 per area
                report.append(f"- `{item.file_path}:{item.line_number}`")
                # pragma: allowlist todo
                report.append(f"  - **{item.todo_type}**: {item.content[:100]}")

            if len(area_items) > 10:
                report.append(f"  - ... and {len(area_items) - 10} more\n")

    # Files with most TODOs  # pragma: allowlist todo
    report.append("\n## Files with Most TODOs\n")  # pragma: allowlist todo
    file_counts: dict[str, int] = defaultdict(int)
    for todo in todos:  # pragma: allowlist todo
        file_counts[todo.file_path] += 1

    top_files = sorted(file_counts.items(), key=lambda x: x[1], reverse=True)[:15]
    for file_path, count in top_files:
        report.append(f"- `{file_path}`: {count} items")

    return "\n".join(report)


def main():
    """Main entry point."""
    parser = argparse.ArgumentParser(description="Extract task items")  # pragma: allowlist todo
    parser.add_argument(
        "--output",
        "-o",
        help="Output file path",
        default="docs/reports/todo-analysis.md",  # pragma: allowlist todo
    )
    parser.add_argument(
        "--format",
        "-f",
        choices=["json", "markdown"],
        default="markdown",
        help="Output format",
    )

    args = parser.parse_args()

    # Get repository root
    root_dir = Path(__file__).resolve().parents[2]

    print(f"Scanning repository at: {root_dir}")
    todos = extract_todos(root_dir)  # pragma: allowlist todo
    print(f"Found {len(todos)} TODO/FIXME items")  # pragma: allowlist todo

    # Generate output
    if args.format == "json":
        output_data = {
            "total": len(todos),  # pragma: allowlist todo
            "items": [asdict(todo) for todo in todos],  # pragma: allowlist todo
        }
        output_content = json.dumps(output_data, indent=2)
    else:
        output_content = generate_markdown_report(todos)  # pragma: allowlist todo

    # Write output
    output_path = root_dir / args.output
    output_path.parent.mkdir(parents=True, exist_ok=True)

    with open(output_path, "w", encoding="utf-8") as f:
        f.write(output_content)

    print(f"Report written to: {output_path}")
    print("\nSummary:")
    print(f"- Total items: {len(todos)}")  # pragma: allowlist todo

    by_priority = defaultdict(int)
    for todo in todos:  # pragma: allowlist todo
        by_priority[todo.priority] += 1

    for priority in ["P0", "P1", "P2"]:
        print(f"- {priority}: {by_priority[priority]}")

    return 0


if __name__ == "__main__":
    sys.exit(main())
