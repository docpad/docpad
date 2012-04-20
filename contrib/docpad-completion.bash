#
#  Completion for foo:
#
#  foo file [filename]
#  foo hostname [hostname]
#
_docpad(){
    local cur prev opts
    COMPREPLY=()
    cur="${COMP_WORDS[COMP_CWORD]}"

    case "${cur}" in
        -*)
            _docpad_options
            ;;
        *)
            _docpad_cmd
            ;;
    esac
}

_docpad_cmd() 
{
    local cur prev opts
    cur="${COMP_WORDS[COMP_CWORD]}"
    prev="${COMP_WORDS[COMP_CWORD-1]}"
    opts="run skeleton render generate watch server install cli info"

    case "${prev}" in
        docpad)
            COMPREPLY=( $(compgen -W "${opts}" -- ${cur}) )
            ;;
        *)
            COMPREPLY=( $(compgen -f ${cur}) )
            ;;
    esac
}

_docpad_options() 
{
    local cur prev opts
    COMPREPLY=()
    cur="${COMP_WORDS[COMP_CWORD]}"
    prev="${COMP_WORDS[COMP_CWORD-1]}"
    opts="--help --version --skeleton --port --debug"

    COMPREPLY=( $(compgen -W "${opts}" -- ${cur}) )
}

complete -F _docpad docpad

