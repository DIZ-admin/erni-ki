# ERNI-KI Code Efficiency Report

**Date:** 2025-12-09  
**Analyzed by:** Devin (Cognition AI)

## Executive Summary

This report identifies several areas in the ERNI-KI codebase where code
efficiency could be improved. The issues range from redundant regex operations
to repeated function calls that could be optimized.

## Efficiency Issues Identified

### 1. Redundant Regex Operations in `scripts/remove-all-emoji.py`

**Location:** `scripts/remove-all-emoji.py`, lines 68-87

**Issue:** The `clean_emoji_from_text()` function performs redundant regex
operations. It first calls `EMOJI_PATTERN.sub("", text)` to remove emojis, then
immediately calls `EMOJI_PATTERN.findall(text)` on the original text just to
count matches. This processes the entire text with the same regex pattern twice.

**Current Code:**

```python
def clean_emoji_from_text(text: str) -> tuple[str, int]:
    emoji_count = 0
    cleaned = EMOJI_PATTERN.sub("", text)
    emoji_count += len(EMOJI_PATTERN.findall(text))  # Redundant regex pass
    ...
```

**Recommended Fix:** Use `re.subn()` which returns both the substituted string
and the count of substitutions in a single pass:

```python
def clean_emoji_from_text(text: str) -> tuple[str, int]:
    emoji_count = 0
    cleaned, unicode_count = EMOJI_PATTERN.subn("", text)
    emoji_count += unicode_count
    ...
```

**Impact:** Reduces regex processing time by approximately 50% for the Unicode
emoji detection phase.

---

### 2. Regex Patterns Compiled on Every Function Call in `scripts/fix-deprecated-metadata.py`

**Location:** `scripts/fix-deprecated-metadata.py`, lines 50-64

**Issue:** The `fix_frontmatter()` function defines regex patterns as string
literals and compiles them on every function call via `re.search()` and
`re.sub()`. When processing hundreds of documentation files, this creates
unnecessary overhead.

**Current Code:**

```python
def fix_frontmatter(content: str, filepath: str, verbose: bool = False) -> tuple[str, list[str]]:
    ...
    status_pattern = r"^(\s*)(?<!translation_)status:\s*(.+)$"
    if re.search(status_pattern, frontmatter, re.MULTILINE):
        new_frontmatter = re.sub(status_pattern, ...)
```

**Recommended Fix:** Pre-compile regex patterns at module level:

```python
STATUS_PATTERN = re.compile(r"^(\s*)(?<!translation_)status:\s*(.+)$", re.MULTILINE)
VERSION_PATTERN = re.compile(r"^(\s*)(?<!doc_)version:\s*(.+)$", re.MULTILINE)

def fix_frontmatter(...):
    if STATUS_PATTERN.search(frontmatter):
        new_frontmatter = STATUS_PATTERN.sub(...)
```

**Impact:** Eliminates repeated regex compilation overhead when processing
multiple files.

---

### 3. Inefficient Emoji Detection in `scripts/validate-no-emoji.py`

**Location:** `scripts/validate-no-emoji.py`, lines 70-90

**Issue:** The `check_file_for_emoji()` function checks for forbidden emojis by
iterating through a list and using `if emoji in content` for each one. This is
O(n\*m) where n is content length and m is the number of forbidden emojis.

**Current Code:**

```python
for emoji in FORBIDDEN_EMOJI:
    if emoji in content:
        found_emoji.append(emoji)
```

**Recommended Fix:** Combine all forbidden emojis into a single regex pattern or
use a set-based approach:

```python
FORBIDDEN_EMOJI_SET = frozenset(FORBIDDEN_EMOJI)
FORBIDDEN_EMOJI_PATTERN = re.compile('|'.join(re.escape(e) for e in FORBIDDEN_EMOJI))

def check_file_for_emoji(file_path: str) -> tuple[bool, list[str]]:
    ...
    text_matches = FORBIDDEN_EMOJI_PATTERN.findall(content)
    found_emoji.extend(text_matches)
```

**Impact:** Reduces time complexity from O(n\*m) to O(n) for text emoji
detection.

---

### 4. Duplicate Language Detection Calls in `scripts/add-missing-frontmatter.py`

**Location:** `scripts/add-missing-frontmatter.py`, lines 84-92

**Issue:** The `process_file()` function calls `detect_language(filepath)`
twice - once in `create_frontmatter()` and once in the print statement.

**Current Code:**

```python
frontmatter = create_frontmatter(filepath)  # calls detect_language internally
...
print(f"  Adding frontmatter (language: {detect_language(filepath)})")  # called again
```

**Recommended Fix:** Store the language in a variable or have
`create_frontmatter()` return the language:

```python
language = detect_language(filepath)
frontmatter = create_frontmatter(filepath, language)
print(f"  Adding frontmatter (language: {language})")
```

**Impact:** Minor performance improvement, but improves code clarity and
maintainability.

---

### 5. File Reading Without Caching in `auth/main.go`

**Location:** `auth/main.go`, lines 305-327

**Issue:** The `getEnvOrFile()` function reads from a file every time it's
called. For secrets that don't change during runtime, this could be cached.

**Current Code:**

```go
func getEnvOrFile(key string) string {
    if val := os.Getenv(key); val != "" {
        return val
    }
    filePath := os.Getenv(key + "_FILE")
    ...
    data, err := os.Open(filePath)
    ...
}
```

**Recommended Fix:** Add a sync.Once or cache mechanism for file-based secrets:

```go
var secretCache sync.Map

func getEnvOrFile(key string) string {
    if val := os.Getenv(key); val != "" {
        return val
    }
    if cached, ok := secretCache.Load(key); ok {
        return cached.(string)
    }
    // Read from file and cache...
}
```

**Impact:** Eliminates repeated file I/O for secret retrieval during request
handling.

---

## Recommendation

The most impactful fix with the clearest improvement is **Issue #1** (redundant
regex operations in `remove-all-emoji.py`). This fix:

- Has a clear, measurable performance benefit
- Is a simple, low-risk change
- Uses Python's built-in `subn()` function which is well-documented
- Affects a script that may process many files

## Next Steps

1. Implement the fix for Issue #1
2. Run existing tests to ensure no regression
3. Create a PR with the fix

---

_This report was generated as part of a code efficiency review of the ERNI-KI
repository._
