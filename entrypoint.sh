#!/bin/bash
set -e

echo "=== Entrypoint: repo cloning ==="

# Configure git credentials for private repos
if [ -n "$GITHUB_TOKEN" ]; then
    git config --global credential.helper store
    echo "https://x-access-token:${GITHUB_TOKEN}@github.com" > ~/.git-credentials
    echo "  GitHub token configured for private repo access"
fi

# Clone or pull repos from GIT_REPOS (comma-separated, optional @branch suffix)
if [ -n "$GIT_REPOS" ]; then
    IFS=',' read -ra REPOS <<< "$GIT_REPOS"
    for entry in "${REPOS[@]}"; do
        entry=$(echo "$entry" | xargs)  # trim whitespace
        [ -z "$entry" ] && continue

        # Parse optional @branch syntax
        if [[ "$entry" == *"@"* ]]; then
            url="${entry%@*}"
            branch="${entry##*@}"
        else
            url="$entry"
            branch=""
        fi

        # Extract repo name from URL
        repo_name=$(basename "$url" .git)
        target_dir="/app/projects/${repo_name}"

        if [ -d "$target_dir/.git" ]; then
            echo "Updating ${repo_name} in ${target_dir}..."
            git -C "$target_dir" fetch --depth 50 origin
            if [ -n "$branch" ]; then
                git -C "$target_dir" checkout "$branch" 2>/dev/null || git -C "$target_dir" checkout -b "$branch" "origin/$branch"
            fi
            git -C "$target_dir" pull --ff-only || echo "  Warning: pull failed (maybe local changes), skipping"
            commit=$(git -C "$target_dir" rev-parse --short HEAD)
            echo "  -> ${repo_name} updated (${commit})"
        else
            echo "Cloning ${url} into ${target_dir}..."
            clone_args=(--depth 50)
            if [ -n "$branch" ]; then
                clone_args+=(--branch "$branch")
            fi
            if git clone "${clone_args[@]}" "$url" "$target_dir"; then
                commit=$(git -C "$target_dir" rev-parse --short HEAD)
                echo "  -> ${repo_name} ready (${commit})"
            else
                echo "  !! Failed to clone ${repo_name} (check GITHUB_TOKEN permissions)"
            fi
        fi
    done
else
    echo "  No GIT_REPOS set, skipping clone step"
fi

echo "=== Entrypoint: starting bot ==="
exec "$@"
