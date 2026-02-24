#!/bin/bash
# UserPromptSubmit hook: 次プロンプト時にウィンドウ名をリセット
if [ -n "$TMUX" ]; then
  tmux set-window-option automatic-rename on
fi
