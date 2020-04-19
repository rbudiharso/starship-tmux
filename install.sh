#!/bin/sh

# requirements
# - git
# - curl

# prepare directory
mkdir -p ~/.local/bin
mkdir -p ~/.config

if ! [ -x "$(command -v tmux)" ]; then
  # install tmux
  echo "tmux not found, installing..."
  curl -sL -o tmux https://github.com/tmux/tmux/releases/download/3.0a/tmux-3.0a-x86_64.AppImage
  chmod +x tmux
  mv tmux ~/.local/bin
fi

# download and install starship
curl -fsSL https://starship.rs/install.sh | bash -s -- --yes --bin-dir ~/.local/bin --platform unknown-linux-musl

# install tpm (tmux plugin manager)
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm

# patch ~/.bashrc
cat > /tmp/bashrc <<END
# ===== user config ======
export PATH=~/.local/bin:\$PATH

eval "\$(starship init bash)"

# auto into tmux session
if [[ -n "\$PS1" ]] && [[ -z "\$TMUX" ]] && [[ -n "\$SSH_CONNECTION" ]]; then
  tmux attach-session -t remote || tmux new-session -s remote
fi
END
cat /tmp/bashrc >> ~/.bashrc

# starship config
cat > ~/.config/starship.toml <<END
prompt_order = [
    "username",
    "directory",
    "package",
    "nix_shell",
    "memory_usage",
    "aws",
    "env_var",
    "cmd_duration",
    "line_break",
    "jobs",
    "time",
    "character",
]

[hostname]
prefix = "@ "

[character]
symbol = "=>"
END

# tmux config
cat > ~/.tmux.conf <<END
set -g @plugin 'tmux-plugins/tpm'
set -g @plugin 'tmux-plugins/tmux-sensible'
set -g @plugin 'tmux-plugins/tmux-pain-control'
set -g @plugin 'tmux-plugins/tmux-copycat'
set -g @plugin 'tmux-plugins/tmux-yank'
set -g @plugin 'tmux-plugins/tmux-prefix-highlight'
set -g @plugin 'soyuka/tmux-current-pane-hostname'
set -g @plugin "arcticicestudio/nord-tmux"

run -b '~/.tmux/plugins/tpm/tpm'

set -g @nord_tmux_no_patched_font "1"
set -g @nord_tmux_show_status_content "0"

set -g status-style "bg=#4c566a,fg=#eceff4"
set -g status-left "#[fg=#bf616a,bg=#ebcb8b,bold] #S "
set -g status-right "#{prefix_highlight} #[bg=#a3be8c,fg=black,bold] #U #[bg=#ebcb8b,fg=#bf616a,bold] #h "
setw -g window-status-format "#[fg=#81a1c1,bg=#4c566a] #I:#W "
setw -g window-status-current-format "#[fg=#2e3440,bg=#81a1c1,bold] #I:#W "
setw -g window-status-separator ""
END

# install tmux plugins
echo ""
echo "Installing tmux plugins"
TMUX_PLUGIN_MANAGER_PATH=~/.tmux/plugins .tmux/plugins/tpm/scripts/install_plugins.sh

# source .bashrc and use tmux
echo ""
echo "All set, run \"source ~/.bashrc\" to start"
echo "Or just disconnect and reconnect your ssh session"
