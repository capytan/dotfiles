#!/bin/bash

# Claude Code コマンドの初期セットアップスクリプト（Mac用）

set -e  # エラーが発生したら即座に終了

# 色付き出力用の変数
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# パスの定義
CLAUDE_DIR="$HOME/.claude"
COMMANDS_LINK="$CLAUDE_DIR/commands"
DOTFILES_COMMANDS="$HOME/dotfiles/configs/claude/commands"

echo -e "${GREEN}Claude Code コマンドのセットアップを開始します...${NC}"

# 1. dotfiles のコマンドディレクトリが存在するか確認
if [ ! -d "$DOTFILES_COMMANDS" ]; then
    echo -e "${RED}エラー: $DOTFILES_COMMANDS が見つかりません。${NC}"
    echo "dotfiles が正しくクローンされているか確認してください。"
    exit 1
fi

# 2. .claude ディレクトリを作成（存在しない場合）
if [ ! -d "$CLAUDE_DIR" ]; then
    echo -e "${YELLOW}.claude ディレクトリを作成しています...${NC}"
    mkdir -p "$CLAUDE_DIR"
fi

# 3. 既存のコマンドディレクトリまたはリンクを確認
if [ -e "$COMMANDS_LINK" ]; then
    if [ -L "$COMMANDS_LINK" ]; then
        # シンボリックリンクの場合
        CURRENT_TARGET=$(readlink "$COMMANDS_LINK")
        if [ "$CURRENT_TARGET" = "$DOTFILES_COMMANDS" ]; then
            echo -e "${GREEN}✓ 既に正しく設定されています！${NC}"
            exit 0
        else
            echo -e "${YELLOW}既存のシンボリックリンクを削除しています...${NC}"
            rm "$COMMANDS_LINK"
        fi
    else
        # 実際のディレクトリまたはファイルの場合
        echo -e "${RED}警告: $COMMANDS_LINK が既に存在します（シンボリックリンクではありません）。${NC}"
        echo "バックアップを作成してから続行します。"
        BACKUP_NAME="${COMMANDS_LINK}.backup.$(date +%Y%m%d_%H%M%S)"
        mv "$COMMANDS_LINK" "$BACKUP_NAME"
        echo -e "${YELLOW}バックアップ先: $BACKUP_NAME${NC}"
    fi
fi

# 4. シンボリックリンクを作成
echo -e "${YELLOW}シンボリックリンクを作成しています...${NC}"
ln -s "$DOTFILES_COMMANDS" "$COMMANDS_LINK"

# 5. 確認
if [ -L "$COMMANDS_LINK" ] && [ -d "$COMMANDS_LINK" ]; then
    echo -e "${GREEN}✓ セットアップが完了しました！${NC}"
    echo -e "${GREEN}  $COMMANDS_LINK -> $DOTFILES_COMMANDS${NC}"
    echo
    echo -e "${GREEN}Claude Code でカスタムコマンドが使用できるようになりました。${NC}"
else
    echo -e "${RED}✗ エラー: シンボリックリンクの作成に失敗しました。${NC}"
    exit 1
fi
