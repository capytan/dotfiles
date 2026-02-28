#!/usr/bin/env zsh
# Development tools setup

# Editor
export EDITOR=nvim

# Neovim aliases
alias vim='nvim'
alias v='nvim'

# mise (development environment manager)
if [[ -x "$HOME/.local/bin/mise" ]]; then
  eval "$($HOME/.local/bin/mise activate zsh)"
  eval "$($HOME/.local/bin/mise activate --shims)"
fi

# pnpm
export PNPM_HOME="$HOME/Library/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac

# git diff to commit message functions
gdcp() {
  (echo "以下のdiffを元に、日本語で簡潔なコミットメッセージを作成してください。

形式：<type>(<optional scope>): <description>

利用可能な type:
- feat: 新機能の追加
- fix: バグ修正
- refactor: リファクタリング（機能追加やバグ修正を含まない）
- perf: パフォーマンス改善
- style: コードスタイルの修正（空白、フォーマット、セミコロン等）
- test: テストの追加・修正
- docs: ドキュメントのみの変更
- build: ビルドプロセス、依存関係の変更
- ops: インフラ、デプロイメント関連の変更
- chore: その他の変更（.gitignore等）

例：
- feat(auth): ユーザー認証機能を追加
- fix(api): レスポンスのステータスコードを修正
- docs: READMEを更新

Breaking Changes がある場合は「!」を追加：
feat(api)!: 認証APIのレスポンス形式を変更

\`\`\`diff
$(git diff --staged)
\`\`\`
"; git diff --staged) | pbcopy
}

gdcpe() {
  (echo "Please write a simple commit message in English based on the following diff.

Format: <type>(<optional scope>): <description>

Available types:
- feat: Add or remove a feature
- fix: Fix a bug
- refactor: Code changes that neither fixes a bug nor adds a feature
- perf: Performance improvements
- style: Changes that do not affect the meaning of the code
- test: Adding or modifying tests
- docs: Documentation only changes
- build: Changes to build process, dependencies, versions
- ops: Changes to infrastructure, deployment, etc
- chore: Other changes like modifying .gitignore

Examples:
- feat(auth): add user authentication feature
- fix(api): correct status code in response
- docs: update README

For Breaking Changes add \"!\":
feat(api)!: change authentication API response format

\`\`\`diff
$(git diff --staged)
\`\`\`
"; git diff --staged) | pbcopy
}
