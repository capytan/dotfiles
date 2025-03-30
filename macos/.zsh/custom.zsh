# setting environment variables

# direnv
if type direnv &>/dev/null; then
  eval "$(direnv hook zsh)"
fi

# rbenv
# eval "$(rbenv init - zsh)"

# Volta - The Hassle-Free JavaScript Tool Manager
# export VOLTA_HOME="$HOME/.volta"
# export PATH="$VOLTA_HOME/bin:$PATH"

# mise
# https://github.com/jdx/mise
if type mise &>/dev/null; then
  eval "$(~/.local/bin/mise activate zsh)"
  eval "$(~/.local/bin/mise activate --shims)"
fi

# tenv
if type tenv &>/dev/null; then
  source $HOME/.tenv.completion.zsh
fi

# history
HISTFILE=~/.zsh_history
HISTSIZE=1000000
SAVEHIST=1000000
setopt share_history         # share history between sessions
setopt hist_ignore_dups      # don't add the same command as previous one to history
setopt hist_ignore_all_dups  # delete the old command if the same command is added again
setopt hist_ignore_space     # don't add commands that start with a space to history
setopt hist_reduce_blanks    # delete extra spaces from history

# aliases
alias vim='nvim'
alias v='nvim'
alias gdcp='(echo "このdiffを元に、日本語で簡潔なコミットメッセージを作成してください。

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
"; git diff --staged) | pbcopy'
alias gdcpe='(echo "Please write a simple commit message in English based on this diff.

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
"; git diff --staged) | pbcopy'

# fzf completion
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

# for fzf completion
# fbr - checkout git branch
fbr() {
  local branches branch
  branches=$(git branch -vv) &&
  branch=$(echo "$branches" | fzf +m) &&
  git switch $(echo "$branch" | awk '{print $1}' | sed "s/.* //")
}

fbrm() {
  local branches branch
  branches=$(git branch --all | grep -v HEAD) &&
  branch=$(echo "$branches" |
           fzf-tmux -d $(( 2 + $(wc -l <<< "$branches") )) +m) &&
  git switch $(echo "$branch" | sed "s/.* //" | sed "s#remotes/[^/]*/##")
}

# for cd completion
fd() {
  local dir
  dir=$(find ${1:-.} -path '*/\.*' -prune \
                        -o -type d -print 2> /dev/null | fzf +m) &&
                      cd "$dir"
}

# ghq with fzf
function fzf-src () {
  local selected_dir=$(ghq list -p | fzf --query "$LBUFFER")
  if [ -n "$selected_dir" ]; then
    BUFFER="cd ${selected_dir}"
    zle accept-line
  fi
  zle clear-screen
}
zle -N fzf-src
bindkey '^]' fzf-src

# OpenSSL@1.1 の場合のセットアップ
# export PATH="$HOMEBREW_PREFIX/opt/openssl@1.1/bin:$PATH"
# export PKG_CONFIG_PATH="$HOMEBREW_PREFIX/opt/openssl@1.1/lib/pkgconfig"
# export RUBY_CONFIGURE_OPTS="$RUBY_CONFIGURE_OPTS --with-openssl-dir=$HOMEBREW_PREFIX/opt/openssl@1.1"

# OpenSSL@3 の場合のセットアップ
# export PATH="$HOMEBREW_PREFIX/opt/openssl@3/bin:$PATH"
# export PKG_CONFIG_PATH="$HOMEBREW_PREFIX/opt/openssl@3/lib/pkgconfig"
# export RUBY_CONFIGURE_OPTS="$RUBY_CONFIGURE_OPTS --enable-yjit --with-openssl-dir=$HOMEBREW_PREFIX/opt/openssl@3"