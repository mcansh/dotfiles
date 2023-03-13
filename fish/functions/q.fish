# https://gist.github.com/asportnoy/a55a7a5df34af008f7ae2fdbbef22f04

# Requires the GitHub Copilot CLI from GitHub Next
# https://www.npmjs.com/package/@githubnext/github-copilot-cli#user-content-installation-and-setup
# This needs do be set up as a function in your fish config. You can use `funced -s q` to do this.

# Options:
# q -g --git: Use github-copilot-cli git-assist
# q -h --gh: Use github-copilot-cli gh-assist
# Defaults to using what-the-shell (general command assist) if neither option is provided

complete -c q -s g -l git -d "Use git assist"
complete -c q -s h -l gh -d "Use GitHub CLI assist"

function q
    argparse -si --name q g/git h/gh -- $argv

    # make sure we're not running an old command if copilot fails later
    rm -rf /tmp/copilot_output

    set query "$argv"
    if not test "$query"
        # prompt user for input if no query is provided
        read --prompt "set_color --bold 6b75ff; echo -n \" What do you want to do? \"; set_color normal; set_color brblack; echo -n \u203a \"\"; set_color normal;" query
    end

    if not test "$query"
        # no query provided, exit
        return 1
    end

    set subcmd what-the-shell
    if test "$_flag_g"
        set subcmd git-assist
    end
    if test "$_flag_h"
        set subcmd gh-assist
    end


    # run copilot
    github-copilot-cli $subcmd --shellout /tmp/copilot_output "On Fish Shell: $query"

    if test "$status" -ne 0
        # copilot failed, exit
        return 1
    end

    # read copilot output
    set cmd (cat /tmp/copilot_output)

    if not test "$cmd"
        # no command from copilot, exit
        return 1
    end

    # execute command
    commandline $cmd
    commandline -f execute
end
