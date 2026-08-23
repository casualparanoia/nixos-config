{ pkgs, lib, ... }:

{
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;

    history = {
      size = 50000;
      save = 100000;
      ignoreDups = true;
      path = "$HOME/.zsh_history";
    };

    setOptions = [
      "NO_BEEP"
      "NO_LIST_BEEP"
      "COMPLETE_IN_WORD"
      "ALWAYS_LAST_PROMPT"
    ];

    initContent = lib.mkMerge [
      (lib.mkOrder 550 ''
        # Load complist before compinit
        zmodload zsh/complist
      '')
      (lib.mkOrder 600 ''
        # Completion menu UI
        zstyle ':completion:*' menu select
        zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'

        # Conservative key timeout
        KEYTIMEOUT=5

        # Cleanly exit menu
        bindkey -M menuselect '^G' send-break
        bindkey -M menuselect '^C' send-break
        bindkey -M menuselect '\e' send-break

        # Bind standard Tab to the menu-select widget directly
        bindkey '^I' menu-select


        # ==========================================
        # Terminal Escape Sequence Keybindings
        # ==========================================
        # Standard xterm / Windows Terminal Ctrl+Left / Ctrl+Right
        bindkey '^[[1;5D' backward-word
        bindkey '^[[1;5C' forward-word

        # Fallback modifier formats across different PTY / tmux layers
        bindkey '^[[5D'   backward-word
        bindkey '^[[5C'   forward-word
        bindkey '^[^[[D'  backward-word
        bindkey '^[^[[C'  forward-word

        # Ctrl + Delete / Ctrl + Backspace (Word Deletion)
        bindkey '^[[3;5~' kill-word
      '')
    ];
  };

  programs.eza.enableZshIntegration = true;
  programs.carapace.enableZshIntegration = true;
  programs.zoxide.enableZshIntegration = true;
  programs.fzf.enableZshIntegration = true;
  programs.yazi.enableZshIntegration = true;
}
