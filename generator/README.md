# 🧩 Programming Challenges Generator – User Guide

A unified tool to **organize**, **track**, and **generate** programming challenge indexes automatically.

Supports both **Bash (Linux/macOS)** and **PowerShell (Windows)**.
Keeps your challenges database consistent and your Markdown indexes always up to date.

---

## ⚙️ Features

* 📂 Organize challenges by category.
* 🧾 Track progress with visual statuses:

  * ⬜ **Not Started**
  * 🟨 **In Progress**
  * ✅ **Done**
* 🪄 Auto-generate category and solution `INDEX.md` files.
* 🔗 Supports **GitHub-friendly links** or **local relative paths**.
* 🧠 Maintains a single **CSV database** as the source of truth.

---

## 🖥️ Supported Platforms

| Platform        | Script File     | Requirements  |
| --------------- | --------------- | ------------- |
| **Linux/macOS** | `generator.sh`  | Bash shell    |
| **Windows**     | `generator.ps1` | PowerShell 5+ |

---

## 📦 Installation

1. Clone your repository containing the challenges.
2. Place the script (`generator.sh` or `generator.ps1`) in the **repository root**.
3. Configure paths and options in the file **`AUTOGEN.conf`**.

---

## ⚙️ Configuration — `AUTOGEN.conf`

Defines paths, templates, and categories used by the generator.

### Example Configuration

```ini
# Base path relative to which all others are resolved
RELATIVE_TO=./

# CSV database file
CHALLENGES_DB_FILE=challenges/challenges.csv

# Root folder for challenge categories
CHALLENGES_ROOT=challenges

# Folder inside each category containing challenge markdown files
CHALLENGES_DETAILS_FOLDER_NAME=details

# Name for category index files
CHALLENGES_INDEX_FILE_NAME=INDEX.md

# Template for category index generation
CHALLENGES_INDEX_FILE_TEMPLATE=templates/category-index.template.md

# Folder containing completed solutions
SOLUTIONS_FOLDER=solutions

# Template for the solutions index
SOLUTIONS_INDEX_FILE_TEMPLATE=templates/solutions-index.template.md

# Allowed challenge categories
VALID_CATEGORIES=applications,programs,games,miscellaneous

# Whether Markdown links should be GitHub-friendly
GITHUB_ABSOLUTE=true
```

### Notes

* All paths are **relative to `RELATIVE_TO`**.
* `VALID_CATEGORIES` prevents typos and ensures consistency.
* Set `GITHUB_ABSOLUTE=true` for absolute paths that work on GitHub.

---

## 🗃️ CSV Database Structure (`challenges.csv`)

This file acts as the **single source of truth** for all challenges.

| Column     | Description                                    |
| ---------- | ---------------------------------------------- |
| `index`    | Global challenge ID                            |
| `category` | Challenge category (e.g., `programs`, `games`) |
| `name`     | Markdown filename of the challenge             |
| `status`   | ⬜ Not started · 🟨 In progress · ✅ Done        |
| `filepath` | Relative path to the challenge markdown file   |

### Display Names

* The first line starting with `#` inside each markdown file is used as the **display name**.
* If missing, the **filename** is used (e.g., `01-test.md` → `01 test`).

---

## 🧰 Commands

### 1. Update Database

Scans challenge folders and adds any new markdown files to the CSV.

```bash
./generator.sh update-db
# or
.\generator.ps1 update-db
```

🧠 Automatically:

* Adds new challenges with status ⬜ *Not Started*.
* Keeps existing data untouched.
* Creates missing folders if needed.

---

### 2. Generate Category Indexes

Builds or refreshes the `INDEX.md` for every category.

```bash
./generator.sh update-indexes
# or
.\generator.ps1 update-indexes
```

📋 Generates tables with:

* Global ID
* Challenge name (linked)
* Status symbol
  → Replaces `{category_table}` in the template with generated content.

---

### 3. Generate Solutions Index

Creates a unified `solutions/INDEX.md` organized by language.

```bash
./generator.sh update-solutions
# or
.\generator.ps1 update-solutions
```

🧩 Automatically:

* Scans `solutions/` by language.
* Matches folders to challenge IDs.
* Generates GitHub-friendly or relative links depending on `GITHUB_ABSOLUTE`.

---

### 4. Full Update

Runs everything — database, category indexes, and solutions index — in one command.

```bash
./generator.sh update-all
# or
.\generator.ps1 update-all
```

---

### 5. Update Challenge Status

Update one or more challenges at once.

```bash
./generator.sh status <ids> <state> [solution-path]
# or
.\generator.ps1 status <ids> <state> [solution-path]
```

| Parameter       | Description                                                          |
| --------------- | -------------------------------------------------------------------- |
| `ids`           | Challenge ID(s), comma or range supported (e.g., `1,2,3` or `10-15`) |
| `state`         | `notstarted`, `wip`, or `done`                                       |
| `solution-path` | Optional when marking as `done`; path to completed solution          |

**Examples**

```bash
# Mark single challenge as done
./generator.sh status 4 done ./solutions/csharp/04-challenge

# Mark multiple as done
./generator.sh status 1,2,3 done

# Mark a range as in progress
./generator.sh status 5-10 wip
```

---

## 🏷️ Display Names

Display names are derived automatically:

1. Uses the first Markdown header (`#`) line in the challenge file.
2. Falls back to filename with `.md` removed and `-` replaced by spaces.

---

## 💡 Tips & Best Practices

* Ensure filenames are **unique** within all categories.
* Always run `update-db` before `update-indexes`.
* Customize templates for your preferred table style.
* Use `update-all` to keep everything perfectly synchronized.

---

## 📖 Example — Category Table

| #  | Challenge                                                 | Status |
| -- | --------------------------------------------------------- | ------ |
| 01 | [01 Test](challenges/applications/details/01-test.md)     | ⬜      |
| 02 | [Hello World](challenges/programs/details/hello-world.md) | 🟨     |
| 03 | [Game Engine](challenges/games/details/game-engine.md)    | ✅      |

---

## 📘 Example — Solutions Table

| #  | Challenge                                                 | Solution                                           |
| -- | --------------------------------------------------------- | -------------------------------------------------- |
| 01 | [01 Test](challenges/applications/details/01-test.md)     | [01 Test](solutions/csharp/01-test)                |
| 02 | [Hello World](challenges/programs/details/hello-world.md) | [Hello World](solutions/python/02-hello-world)     |
| 03 | [Game Engine](challenges/games/details/game-engine.md)    | [Game Engine](solutions/javascript/03-game-engine) |

---

## 🧩 Summary

**Programming Challenges Generator** keeps your project clean and consistent by:

* Managing all challenges from a single CSV.
* Automatically generating indexes and tracking progress.
* Making GitHub-ready documentation effortless.

