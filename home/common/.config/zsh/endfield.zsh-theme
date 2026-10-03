# Endfield prompt.
#
# Two lines, because the command should always start at the same column: a
# path pushed into the prompt moves where you type, and the eye has to find it
# again on every command.
#
# The palette by hand rather than through the ANSI slots: a prompt is interface
# and the ANSI colours are for whatever a program prints. Colours here are the
# roles from .config/theme/endfield.conf.

local accent="%F{#FFD400}"
local danger="%F{#FF6B45}"
local secondary="%F{#AAB7C2}"
local muted="%F{#8A99A6}"
local off="%f"

# The accent tick that marks a heading everywhere else on this desktop.
# Local shells stay minimal; SSH shells include user@host so the remote context
# is always visible without making the normal prompt noisier.
local remote=""
if [[ -n "${SSH_CONNECTION:-}" ]]; then
    remote="${muted}%n@%m${off} "
fi

PROMPT="${accent}▎${off} ${remote}${secondary}%2~${off}"'$(git_prompt_info)'"
%(?.${accent}.${danger})❯${off} "

# A failing command leaves its code at the right edge, where every other
# surface here puts a reading.
RPROMPT="%(?..${danger}%?${off})"

ZSH_THEME_GIT_PROMPT_PREFIX=" ${muted}󰘬 "
ZSH_THEME_GIT_PROMPT_SUFFIX="${off}"
# Dirty is worth the accent; clean has nothing to say.
ZSH_THEME_GIT_PROMPT_DIRTY="${accent}*${off}"
ZSH_THEME_GIT_PROMPT_CLEAN=""
