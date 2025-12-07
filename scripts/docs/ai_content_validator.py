#!/usr/bin/env python3
"""
AI-powered documentation quality validator using GitHub Models API.

Uses GPT-4o-mini to analyze markdown documentation for:
- Completeness (required sections)
- Readability (structure, clarity)
- Consistency (terminology, formatting)

Usage:
    python scripts/docs/ai-content-validator.py docs/readme.md
    python scripts/docs/ai-content-validator.py docs/ --recursive
    python scripts/docs/ai-content-validator.py docs/ --ci --output results.json
"""

from __future__ import annotations

import argparse
import json
import os
import re
import sys
from dataclasses import dataclass, field
from pathlib import Path
from typing import TYPE_CHECKING

if TYPE_CHECKING:
    from openai import OpenAI

# GitHub Models configuration
ENDPOINT = "https://models.github.ai/inference"
MODEL = "openai/gpt-4o-mini"

# Required sections for different doc types
REQUIRED_SECTIONS = {
    "default": ["overview", "summary"],
    "tutorial": ["prerequisites", "steps", "next steps"],
    "reference": ["description", "parameters", "examples"],
    "guide": ["overview", "prerequisites", "conclusion"],
}

# Project terminology for consistency checks (correct forms)
PROJECT_TERMS = {
    "openwebui": "OpenWebUI",
    "open-webui": "OpenWebUI",
    "litellm": "LiteLLM",
    "lite-llm": "LiteLLM",
    "docker-compose": "Docker Compose",
    "dockercompose": "Docker Compose",
    "github actions": "GitHub Actions",
    "github-actions": "GitHub Actions",
    "prometheus": "Prometheus",
    "grafana": "Grafana",
}


@dataclass
class ValidationIssue:
    """A single validation issue found in a document."""

    issue_type: str
    message: str
    severity: str = "warning"  # info, warning, error
    line: int | None = None


@dataclass
class ValidationResult:
    """Result of validating a single document."""

    file_path: str
    score: int = 100
    issues: list[ValidationIssue] = field(default_factory=list)
    suggestions: list[str] = field(default_factory=list)
    ai_analysis: str = ""

    def to_dict(self) -> dict:
        """Convert to dictionary for JSON serialization."""
        return {
            "file": self.file_path,
            "score": self.score,
            "issues": [
                {
                    "type": i.issue_type,
                    "message": i.message,
                    "severity": i.severity,
                    "line": i.line,
                }
                for i in self.issues
            ],
            "suggestions": self.suggestions,
            "ai_analysis": self.ai_analysis,
        }


def get_openai_client() -> OpenAI:
    """Create OpenAI client configured for GitHub Models."""
    try:
        from openai import OpenAI
    except ImportError:
        print("Error: openai package not installed. Run: pip install openai")
        sys.exit(1)

    token = os.environ.get("GITHUB_TOKEN")
    if not token:
        print("Error: GITHUB_TOKEN environment variable not set")
        sys.exit(1)

    return OpenAI(base_url=ENDPOINT, api_key=token)


def detect_doc_type(content: str, file_path: str) -> str:
    """Detect document type based on content and path."""
    path_lower = file_path.lower()

    if "tutorial" in path_lower or "guide" in path_lower:
        return "tutorial"
    if "reference" in path_lower or "api" in path_lower:
        return "reference"
    if "academy" in path_lower:
        return "guide"
    return "default"


def check_structure(content: str) -> list[ValidationIssue]:
    """Check document structure without AI."""
    issues = []
    lines = content.split("\n")

    # Check for headings
    headings = [line for line in lines if line.startswith("#")]
    if len(headings) < 2:
        issues.append(
            ValidationIssue(
                issue_type="structure",
                message="Document has fewer than 2 headings - consider adding more structure",
                severity="warning",
            )
        )

    # Check for very long paragraphs
    current_paragraph = []
    for i, line in enumerate(lines):
        if line.strip():
            current_paragraph.append(line)
        else:
            if len(current_paragraph) > 15:
                para_len = len(current_paragraph)
                issues.append(
                    ValidationIssue(
                        issue_type="readability",
                        message=f"Long paragraph (~{para_len} lines) - consider breaking",
                        severity="info",
                        line=max(1, i - para_len + 1),  # Convert to 1-indexed
                    )
                )
            current_paragraph = []

    # Check remaining paragraph at end of file (if no trailing newline)
    if len(current_paragraph) > 15:
        para_len = len(current_paragraph)
        issues.append(
            ValidationIssue(
                issue_type="readability",
                message=f"Long paragraph (~{para_len} lines) - consider breaking",
                severity="info",
                line=max(1, len(lines) - para_len + 1),
            )
        )

    # Check for code blocks
    code_blocks = content.count("```")
    if code_blocks % 2 != 0:
        issues.append(
            ValidationIssue(
                issue_type="formatting",
                message="Unbalanced code blocks (odd number of ```)",
                severity="error",
            )
        )

    return issues


def check_completeness(content: str, doc_type: str) -> list[ValidationIssue]:
    """Check for required sections based on document type."""
    issues = []
    content_lower = content.lower()

    required = REQUIRED_SECTIONS.get(doc_type, REQUIRED_SECTIONS["default"])

    for section in required:
        # Check for section as heading or keyword
        if section not in content_lower:
            issues.append(
                ValidationIssue(
                    issue_type="completeness",
                    message=f"Missing recommended section: '{section}'",
                    severity="info",
                )
            )

    return issues


def check_terminology(content: str) -> list[ValidationIssue]:
    """Check for consistent terminology usage."""
    issues = []
    content_lower = content.lower()

    # Check for common misspellings/inconsistencies using PROJECT_TERMS
    for incorrect, correct in PROJECT_TERMS.items():
        if incorrect in content_lower and correct not in content:
            issues.append(
                ValidationIssue(
                    issue_type="consistency",
                    message=f"Consider using '{correct}' instead of '{incorrect}'",
                    severity="info",
                )
            )

    return issues


def analyze_with_ai(client: OpenAI, content: str, file_path: str) -> dict:
    """Use AI to analyze document quality."""
    prompt = f"""Analyze this documentation file for quality. Be concise.

File: {file_path}

Content (truncated to first 4000 chars):
{content[:4000]}

Provide a JSON response with:
1. "score": 0-100 quality score
2. "issues": array of {{"type": "completeness|readability|consistency", "message": "..."}}
3. "suggestions": array of improvement suggestions (max 3)

Focus on:
- Is the content clear and well-structured?
- Are there any missing important sections?
- Is the technical accuracy apparent?

Respond with ONLY valid JSON, no markdown formatting."""

    try:
        response = client.chat.completions.create(
            model=MODEL,
            messages=[
                {
                    "role": "system",
                    "content": "You are a technical documentation reviewer. "
                    "Respond only with valid JSON.",
                },
                {"role": "user", "content": prompt},
            ],
            max_tokens=500,
            temperature=0.3,
        )

        result_text = response.choices[0].message.content or "{}"

        # Clean up response (extract JSON from markdown code block if present)
        match = re.search(r"```(?:json)?\s*([\s\S]*?)```", result_text)
        if match:
            result_text = match.group(1).strip()

        return json.loads(result_text)

    except json.JSONDecodeError:
        return {"score": 70, "issues": [], "suggestions": ["AI analysis unavailable"]}
    except Exception as e:
        return {"score": 70, "issues": [], "suggestions": [f"AI error: {e!s}"]}


def validate_file(
    file_path: Path, client: OpenAI | None = None, use_ai: bool = True
) -> ValidationResult:
    """Validate a single markdown file."""
    result = ValidationResult(file_path=str(file_path))

    try:
        content = file_path.read_text(encoding="utf-8")
    except Exception as e:
        result.issues.append(
            ValidationIssue(
                issue_type="error", message=f"Could not read file: {e}", severity="error"
            )
        )
        result.score = 0
        return result

    # Skip very short files
    if len(content) < 100:
        result.issues.append(
            ValidationIssue(
                issue_type="completeness",
                message="File is very short (<100 chars)",
                severity="info",
            )
        )
        result.score = 50
        return result

    # Detect document type
    doc_type = detect_doc_type(content, str(file_path))

    # Run structural checks (no AI)
    result.issues.extend(check_structure(content))
    result.issues.extend(check_completeness(content, doc_type))
    result.issues.extend(check_terminology(content))

    # Calculate base score from structural issues
    error_count = sum(1 for i in result.issues if i.severity == "error")
    warning_count = sum(1 for i in result.issues if i.severity == "warning")
    info_count = sum(1 for i in result.issues if i.severity == "info")

    base_score = 100 - (error_count * 20) - (warning_count * 10) - (info_count * 2)

    # Run AI analysis if enabled and client available
    if use_ai and client:
        ai_result = analyze_with_ai(client, content, str(file_path))

        # Merge AI results (clamp to 0-100)
        ai_score = ai_result.get("score", 70)
        result.score = max(0, min(100, int((base_score + ai_score) / 2)))

        for issue in ai_result.get("issues", []):
            result.issues.append(
                ValidationIssue(
                    issue_type=issue.get("type", "ai"),
                    message=issue.get("message", ""),
                    severity="warning",
                )
            )

        result.suggestions = ai_result.get("suggestions", [])
    else:
        result.score = max(0, min(100, base_score))

    return result


def validate_directory(
    dir_path: Path,
    client: OpenAI | None = None,
    use_ai: bool = True,
    recursive: bool = True,
) -> list[ValidationResult]:
    """Validate all markdown files in a directory."""
    results = []

    md_files = list(dir_path.rglob("*.md") if recursive else dir_path.glob("*.md"))

    for file_path in md_files:
        # Skip node_modules, .git, etc.
        if any(part.startswith(".") or part == "node_modules" for part in file_path.parts):
            continue

        result = validate_file(file_path, client, use_ai)
        results.append(result)

    return results


def print_results(results: list[ValidationResult], verbose: bool = False) -> None:
    """Print validation results to console."""
    total_score = 0
    total_files = len(results)

    for result in results:
        total_score += result.score

        # Color coding based on score
        if result.score >= 80:
            status = "PASS"
        elif result.score >= 60:
            status = "WARN"
        else:
            status = "FAIL"

        print(f"[{status}] {result.file_path}: {result.score}/100")

        if verbose or result.score < 80:
            for issue in result.issues:
                prefix = {"error": "!!", "warning": "!", "info": "-"}.get(issue.severity, "-")
                print(f"  {prefix} [{issue.issue_type}] {issue.message}")

            for suggestion in result.suggestions:
                print(f"  > {suggestion}")

    if total_files > 0:
        avg_score = total_score / total_files
        print(f"\nTotal: {total_files} files, Average score: {avg_score:.1f}/100")


def main() -> int:
    """Main entry point."""
    parser = argparse.ArgumentParser(description="AI-powered documentation quality validator")
    parser.add_argument("path", help="File or directory to validate")
    parser.add_argument(
        "--recursive", "-r", action="store_true", help="Recursively scan directories"
    )
    parser.add_argument(
        "--ci", action="store_true", help="CI mode: output JSON, exit 1 on failures"
    )
    parser.add_argument("--output", "-o", help="Output file for JSON results")
    parser.add_argument("--no-ai", action="store_true", help="Skip AI analysis (faster, offline)")
    parser.add_argument("--verbose", "-v", action="store_true", help="Verbose output")
    parser.add_argument(
        "--threshold",
        type=int,
        default=60,
        help="Minimum score threshold (default: 60)",
    )

    args = parser.parse_args()

    path = Path(args.path)

    if not path.exists():
        print(f"Error: Path not found: {path}")
        return 1

    # Initialize AI client if needed
    client = None
    if not args.no_ai:
        if os.environ.get("GITHUB_TOKEN"):
            client = get_openai_client()
        else:
            print("Warning: GITHUB_TOKEN not set, running without AI analysis")

    # Run validation
    if path.is_file():
        results = [validate_file(path, client, not args.no_ai)]
    else:
        results = validate_directory(path, client, not args.no_ai, args.recursive)

    # Output results
    if args.ci or args.output:
        output_data = {
            "total_files": len(results),
            "average_score": sum(r.score for r in results) / len(results) if results else 0,
            "threshold": args.threshold,
            "results": [r.to_dict() for r in results],
        }

        if args.output:
            with open(args.output, "w", encoding="utf-8") as f:
                json.dump(output_data, f, indent=2)

        if args.ci:
            print(json.dumps(output_data, indent=2))
    else:
        print_results(results, args.verbose)

    # Check threshold for CI
    if args.ci:
        failures = [r for r in results if r.score < args.threshold]
        if failures:
            print(
                f"\n{len(failures)} file(s) below threshold ({args.threshold})",
                file=sys.stderr,
            )
            return 1

    return 0


if __name__ == "__main__":
    sys.exit(main())
