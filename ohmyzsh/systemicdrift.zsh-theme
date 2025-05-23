functions rbenv_prompt_info >& /dev/null || rbenv_prompt_info(){}


function theme_precmd {
    local TERMWIDTH
    (( TERMWIDTH = ${COLUMNS} - 1 ))


    ###
    # Truncate the path if it's too long.

    PR_FILLBAR=""
    PR_PWDLEN=""

    local promptsize=${#${(%):---(%n@%m:%l)---()--}}
    local rubyprompt=`rvm_prompt_info || rbenv_prompt_info`
    local rubypromptsize=${#${rubyprompt}}
    local pwdsize=${#${(%):-%~}}

    if [[ "$promptsize + $rubypromptsize + $pwdsize" -gt $TERMWIDTH ]]; then
      ((PR_PWDLEN=$TERMWIDTH - $promptsize))
    else
      PR_FILLBAR="\${(l.(($TERMWIDTH + 3 - ($promptsize + $rubypromptsize + $pwdsize)))..${PR_HBAR}.)}"
    fi

}


setopt extended_glob
theme_preexec () {
    if [[ "$TERM" == "screen" ]]; then
	local CMD=${1[(wr)^(*=*|sudo|-*)]}
	echo -n "\ek$CMD\e\\"
    fi
}


setprompt () {
    ###
    # Need this so the prompt will work.

    setopt prompt_subst


    ###
    # See if we can use colors.

    autoload zsh/terminfo
    for color in RED GREEN YELLOW BLUE MAGENTA CYAN WHITE GREY; do
	eval PR_$color='%{$terminfo[bold]$fg[${(L)color}]%}'
	eval PR_LIGHT_$color='%{$fg[${(L)color}]%}'
	(( count = $count + 1 ))
    done
    PR_NO_COLOUR="%{$terminfo[sgr0]%}"

    ###
    # Modify Git prompt
    ZSH_THEME_GIT_PROMPT_PREFIX=" on %{$fg[green]%}"
    ZSH_THEME_GIT_PROMPT_SUFFIX="%{$reset_color%}"
    ZSH_THEME_GIT_PROMPT_DIRTY=""
    ZSH_THEME_GIT_PROMPT_CLEAN=""

    ZSH_THEME_GIT_PROMPT_ADDED=" ✚ "

    ZSH_THEME_GIT_PROMPT_MODIFIED=" ✹ "
    ZSH_THEME_GIT_PROMPT_DELETED=" ✖ "
    ZSH_THEME_GIT_PROMPT_RENAMED=" ➜ "
    ZSH_THEME_GIT_PROMPT_UNMERGED=" ═ "
    ZSH_THEME_GIT_PROMPT_UNTRACKED=" ✭ "



    ###
    # See if we can use extended characters to look nicer.
    # UTF-8 Fixed

    if [[ $(locale charmap) == "UTF-8" ]]; then
	PR_SET_CHARSET=""
	PR_SHIFT_IN=""
	PR_SHIFT_OUT=""
	PR_HBAR="─"
        PR_ULCORNER="┌"
        PR_LLCORNER="└"
        PR_LRCORNER="┘"
        PR_URCORNER="┐"
    else
        typeset -A altchar
        set -A altchar ${(s..)terminfo[acsc]}
        # Some stuff to help us draw nice lines
        PR_SET_CHARSET="%{$terminfo[enacs]%}"
        PR_SHIFT_IN="%{$terminfo[smacs]%}"
        PR_SHIFT_OUT="%{$terminfo[rmacs]%}"
        PR_HBAR='$PR_SHIFT_IN${altchar[q]:--}$PR_SHIFT_OUT'
        PR_ULCORNER='$PR_SHIFT_IN${altchar[l]:--}$PR_SHIFT_OUT'
        PR_LLCORNER='$PR_SHIFT_IN${altchar[m]:--}$PR_SHIFT_OUT'
        PR_LRCORNER='$PR_SHIFT_IN${altchar[j]:--}$PR_SHIFT_OUT'
        PR_URCORNER='$PR_SHIFT_IN${altchar[k]:--}$PR_SHIFT_OUT'
     fi


    ###
    # Decide if we need to set titlebar text.

    case $TERM in
	xterm*)
	    PR_TITLEBAR=$'%{\e]0;%(!.-=*[ROOT]*=- | .)%n@%m:%~ | ${COLUMNS}x${LINES} | %y\a%}'
	    ;;
	screen)
	    PR_TITLEBAR=$'%{\e_screen \005 (\005t) | %(!.-=[ROOT]=- | .)%n@%m:%~ | ${COLUMNS}x${LINES} | %y\e\\%}'
	    ;;
	*)
	    PR_TITLEBAR=''
	    ;;
    esac


    ###
    # Decide whether to set a screen title
    if [[ "$TERM" == "screen" ]]; then
	PR_STITLE=$'%{\ekzsh\e\\%}'
    else
	PR_STITLE=''
    fi


    ###
    # Finally, the prompt.
	#    $PR_LIGHT_BLUE%{$reset_color%}`git_prompt_info``git_prompt_status`$PR_RED]$PR_RED$PR_HBAR\
	# $PR_RED%(!.%SROOT%s.%n)$PR_RED@$PR_GREEN%m:%l\
	# charge=$(battery)
	# charge=${charge%.*}
    # percent=$((charge - 0))
    percent=${$(battery)}
    BAT=""
    if [[ "$percent" != "?" || -z "$percent" ]]; then
        color_green="%{$fg[green]%}"
        color_yellow="%{$fg[yellow]%}"
        color_red="%{$fg[red]%}"
        color_reset="%{$reset_color%}"

        if [ $percent -ge 80 ] ; then
            color=$color_green;
        elif [ $percent -ge 40 ] ; then
            color=$color_yellow;
        else
            color=$color_red;
        fi
        end="%%  "
        strt=""
        if [ $percent -le 99 ] ; then
            strt+=" "
        fi
        if [ $percent -le 9 ] ; then
            strt+=" "
        fi
        BAT="($color$strt$percent$end$fg[red]%)"
    fi


# $PR_RED$PR_HBAR$PR_URCORNER\
    PROMPT='$PR_SET_CHARSET$PR_STITLE${(e)PR_TITLEBAR}\
$PR_RED$PR_ULCORNER$PR_HBAR$BAT$PR_RED$PR_HBAR\
$PR_RED(\
$PR_GREEN%$PR_PWDLEN<...<%~%<<\
$PR_RED)`rvm_prompt_info || rbenv_prompt_info`$PR_RED\

$PR_RED$PR_LLCORNER$PR_RED$PR_HBAR(%h) [\
$PR_LIGHT_BLUE%{$reset_color%}`git_prompt_info``git_prompt_status`$PR_RED]$PR_RED$PR_HBAR\
$PR_RED$PR_HBAR\
⚡$PR_NO_COLOUR  '

    # display exitcode on the right when >0
    return_code="%(?..%{$fg[red]%}%? ↵ %{$reset_color%})"
    RPROMPT=' $return_code$PR_RED\
($PR_YELLOW%D{%a, %b %d - %H:%M:%S}$PR_RED)$PR_NO_COLOUR'
#($PR_YELLOW%D{%a, %b %d - %H:%M:%S}$PR_RED)$PR_HBAR$PR_RED$PR_LRCORNER$PR_NO_COLOUR'

    PS2='$PR_RED$PR_HBAR\
$PR_BLUE$PR_HBAR(\
$PR_LIGHT_GREEN%_$PR_BLUE)$PR_HBAR\
$PR_RED$PR_HBAR$PR_NO_COLOUR '
}

setprompt

autoload -U add-zsh-hook
add-zsh-hook precmd  theme_precmd
add-zsh-hook preexec theme_preexec
