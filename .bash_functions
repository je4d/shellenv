#!/bin/bash

function col_
{
#
#Esc[Value;...;Valuem
#	Set Graphics Mode: Calls the graphics functions specified by the following values. These specified functions remain active until the next occurrence of this escape sequence. Graphics mode changes the colors and attributes of text (such as bold and underline) displayed on the screen.
#
#	Text attributes
#	0 All attributes off
#	1 Bold on
#	4 Underscore (on monochrome display adapter only)
#	5 Blink on
#	7 Reverse video on
#	8 Concealed on
#
#	Foreground colors
#	30 Black
#	31 Red
#	32 Green
#	33 Yellow
#	34 mBlue
#	35 Magenta
#	36 Cyan
#	37 White
#
#	Background colors
#	40 Black
#	41 Red
#	42 Green
#	43 Yellow
#	44 Blue
#	45 Magenta
#	46 Cyan
#	47 White
#
#	Parameters 30 through 47 meet the ISO 6429 standard.

	local -A colors=(
			[black]=30
			[red]=31
			[green]=32
			[yellow]=33
			[blue]=34
			[magenta]=35
			[cyan]=36
			[white]=37
			)
	if [ x"$1" = xnone ]; then
		code="0"
	else
		opt=""
		col=$1
		offset=0
		if [ x${col#bg} != x${col} ]; then
			offset=10
			col=${col#bg}
		fi
		if [ x${col#em} != x${col} ]; then
			opt="01;"
			col=${col#em}
		fi
		code=$((${colors[$col]}+$offset))
		if [ -z "$code" ]; then
			echo "Bad colour" >&2
			return
		fi
		code="$opt$code"
	fi
	echo -n "$code"
}

function col {
	echo -n '['$(col_ "$1")m
	if [ -n "$2" ]; then
		echo -n "$2"
		col none
	fi
}

function pcol {
	echo -n '\[\033['$(col_ "$1")'m\]'
}

function setup_prompt {
	# this function sets the following variables in the user's environment
	# PROMPT_COMMAND
	# JE4D_PROMPT_PREEXEC
	#  this holds the code that we put in the DEBUG trap. It's stored in this
	#  var because PROMPT_COMMAND needs to un-set and re-set it.
	# JE4D_PROMPT_RETCODE
	#
	# JE4D_PROMPT_SHOW_RETCODE
	local PS1_="$(pcol $NAME)\\u$(pcol none)@$(pcol $HOST)\\h$(pcol none) $(pcol emblue)\\W$(pcol none) $(pcol $CONN)\\\$$(pcol none) "

	PROMPT_COMMAND="\
			JE4D_PROMPT_RETCODE=\$?;\
			trap - DEBUG; \
			PS1_RETCODE=\`[ \$((\$JE4D_PROMPT_SHOW_RETCODE * \$JE4D_PROMPT_RETCODE)) -gt 0 ] && echo -n '$(pcol bgred)'\"\$JE4D_PROMPT_RETCODE\"'$(pcol none) '\`
			PS1=\"\$PS1_RETCODE\"\"$PS1_\";\
			JE4D_PROMPT_SHOW_RETCODE=0;\
			unset JE4D_PROMPT_RETCODE;\
			unset PS1_RETCODE
			trap \"\$JE4D_PROMPT_PREEXEC\" DEBUG;\
			"

	JE4D_PROMPT_PREEXEC='[ "$BASH_COMMAND" != "trap - DEBUG" -a "$BASH_COMMAND" != "JE4D_PROMPT_RETCODE=\$?" ] && JE4D_PROMPT_SHOW_RETCODE=1'
	trap "$JE4D_PROMPT_PREEXEC" DEBUG
	JE4D_PROMPT_SHOW_RETCODE=0
}

# arg format is file:func
function lazyload
{
	for arg; do
		func=${arg##*:}
		file=${arg%:*}
		eval "function $func { unset -f $func; echo \"Loading $file for function $func\"; . \"$file\"; $func \"\$@\"; }"
	done
}

