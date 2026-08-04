# OH MY ZSH settings
export ZSH="$HOME/.oh-my-zsh"

# Dotfiles root (must be set before globbing for topic files)
export DOTFILES="${DOTFILES:-$HOME/.dotfiles}"

# Load OMZ configuration from topic file (must be before sourcing OMZ)
if [[ -f "$HOME/.dotfiles/zsh/omz-config.zsh" ]]; then
  source "$HOME/.dotfiles/zsh/omz-config.zsh"
fi

# Load Oh My ZSH
source $ZSH/oh-my-zsh.sh


# Stash your environment variables in ~/.localrc. This means they'll stay out
# of your main dotfiles repository (which may be public, like this one), but
# you'll have access to them in your scripts.
if [[ -a ~/.localrc ]]
then
  source ~/.localrc
fi

# ---------------------------------------------------------------------------
# Shell loading order (explicit phases)
#
# Phase 1: Homebrew — must be first so brew-installed tools are on PATH
# Phase 2: path.zsh — each topic prepends to PATH (mise activate, etc.)
# Phase 3: config/env/aliases/functions — general shell setup
# Phase 4: init.zsh — tool initialisers (starship, atuin, broot, vscode)
# Phase 5: compinit — initialise zsh completion system
# Phase 6: completion.zsh — tools that register completions (zoxide, etc.)
# ---------------------------------------------------------------------------

# Collect all topic zsh files once
typeset -U config_files
config_files=($DOTFILES/**/*.zsh)

# --- Phase 1: Homebrew ---------------------------------------------------
if test "$(uname)" = "Darwin"; then
    eval "$(/opt/homebrew/bin/brew shellenv)" 2>/dev/null
elif test "$(expr substr $(uname -s) 1 5)" = "Linux"; then
    eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)" 2>/dev/null
fi

# --- Phase 2: PATH and fpath setup ----------------------------------------
for file in ${(M)config_files:#*/path.zsh} ${(M)config_files:#*/fpath.zsh}; do
  source $file
done

# --- Phase 3: Config, env, aliases, functions -----------------------------
for file in ${${${${config_files:#*/path.zsh}:#*/completion.zsh}:#*/init.zsh}:#*/fpath.zsh}; do
  source $file
done

# --- Phase 4: Tool initialisers (after PATH and env are ready) ------------
for file in ${(M)config_files:#*/init.zsh}; do
  source $file
done

# Normalize Home/End keys across terminals
if [[ -n ${terminfo[khome]} ]]; then
  bindkey "${terminfo[khome]}" beginning-of-line
  bindkey -M vicmd "${terminfo[khome]}" beginning-of-line 2>/dev/null
fi
if [[ -n ${terminfo[kend]} ]]; then
  bindkey "${terminfo[kend]}" end-of-line
  bindkey -M vicmd "${terminfo[kend]}" end-of-line 2>/dev/null
fi

# --- Phase 5: Completion system -------------------------------------------
autoload -Uz compinit
compinit
autoload -Uz +X bashcompinit && bashcompinit

if command -v terraform >/dev/null 2>&1; then
  complete -o nospace -C "$(command -v terraform)" terraform
fi

if [ -d "$HOME/.docker/completions" ]; then
  fpath=("$HOME/.docker/completions" $fpath)
fi

if command -v uvx >/dev/null 2>&1; then
  eval "$(uvx --generate-shell-completion zsh)"
fi

# --- Phase 6: Post-compinit completions -----------------------------------
for file in ${(M)config_files:#*/completion.zsh}; do
  source $file
done

unset config_files
export PATH="/opt/homebrew/opt/llvm/bin:$PATH"
export LDFLAGS="-L/opt/homebrew/opt/llvm/lib"
export CPPFLAGS="-I/opt/homebrew/opt/llvm/include"
