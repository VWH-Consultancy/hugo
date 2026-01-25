# VWH Consultancy Hugo Site

This is a static website built with [Hugo](https://gohugo.io) and the [Terminal theme](https://github.com/panr/hugo-theme-terminal).

## Prerequisites

- **Git** (to clone the repository and submodules)
- **Hugo** (extended version recommended)

## Quick Start

### 1. Clone the repository

```bash
git clone https://github.com/vwh-consultancy/hugo.git
cd hugo
```

### 2. Initialize the theme submodule

The site uses the Terminal theme as a Git submodule. After cloning, run:

```bash
git submodule update --init --recursive
```

If you encounter a “dubious ownership” error, add the directory as safe:

```bash
git config --global --add safe.directory /path/to/hugo
git config --global --add safe.directory /path/to/hugo/themes/terminal
```

### 3. Install Hugo

#### Option A: Install via package manager (may be older)

```bash
# Ubuntu/Debian
sudo apt update
sudo apt install hugo

# macOS with Homebrew
brew install hugo
```

#### Option B: Install the exact extended version used in CI (recommended)

```bash
HUGO_VERSION=0.154.5
wget -O /tmp/hugo.deb "https://github.com/gohugoio/hugo/releases/download/v${HUGO_VERSION}/hugo_extended_${HUGO_VERSION}_linux-amd64.deb"
sudo dpkg -i /tmp/hugo.deb
```

Verify the installation:

```bash
hugo version
```

Expected output: `hugo v0.154.5+extended linux/amd64` (or similar).

### 4. Run the development server

```bash
cd /path/to/hugo
hugo server --baseURL http://localhost:1313
```

The site will be available at **http://localhost:1313**.

**Important:** The `--baseURL` flag ensures CSS and other assets are correctly linked when viewing locally. Without it, the site may appear unstyled because the theme expects the production URL.

### 5. Additional useful flags

- Include draft posts: `hugo server -D`
- Bind to all network interfaces (accessible from other devices): `hugo server --bind 0.0.0.0`
- Custom port: `hugo server --port 8080`
- Disable fast render (if assets aren’t updating): `hugo server --disableFastRender`

## Project Structure

- `hugo.toml` – Main configuration file
- `content/` – Markdown content for pages and posts
- `assets/css/custom.css` – Custom CSS overrides
- `themes/terminal/` – Theme files (Git submodule)
- `public/` – Generated static site (do not edit directly)

## Building for Production

To generate the static site into the `public/` directory:

```bash
hugo
```

The built site can be deployed to any static hosting service (GitHub Pages, Netlify, etc.).

## Troubleshooting

### CSS not rendering locally

If the site loads without styles, make sure:

1. The theme submodule is initialized (step 2 above).
2. You are using the `--baseURL http://localhost:1313` flag when running `hugo server`.
3. The Hugo extended version is installed (check with `hugo version`).

### “dubious ownership” error

This occurs when Git detects the repository is owned by a different user. Fix with:

```bash
git config --global --add safe.directory /path/to/hugo
git config --global --add safe.directory /path/to/hugo/themes/terminal
```

### Theme not found

If you see errors about missing layouts, ensure the submodule is cloned:

```bash
git submodule status
```

If the `themes/terminal` directory is empty, re‑run:

```bash
git submodule update --init --recursive
```

## License

The content of this site is proprietary. The Terminal theme is licensed under the MIT License.