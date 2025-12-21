# 🔒 ARCHIVED: Initial Project Prompt

**Status**: Historical Reference Only
**Date**: 2025-12-19
**Current Documentation**: See `../tasks.md` for current status

---

# Initial Project Prompt

Help me plan a bigger project in this directory. We need to leave instructions in CLAUDE.md for futher runs with coding agents. The goal is to build and upbound control plane project which has feature parity with this terraform aws vpc module: https://github.com/terraform-aws-modules/terraform-aws-vpc

It is crucial that the operating base for coding agents lives in a folder called "thoughts". What will live there are:
- coding patterns and standards in a folder thoughts/coding
- commnoly used operations for maintaining the project in a folder thoughts/git
- the spec for building the application in a folder called thoughts/spec
- instructions on how to operate different commands used while building the project (for example up-cli) in a folder thoughts/tools

Create a plan to lay out the foundation for this but CONCENTRATE ONLY on creating the thoughts folder and its content for now. Things you should start with are for example, but not limited to
- launch an explore agent to deeply research the codebase of the terraform module. concentrate on discovering the spec by examining the TESTS as they will be the main base for verifying that our code works and is compatible
- launch an explore agent to research deeploy about up-cli (https://docs.upbound.io/manuals/cli/overview/). we need to leave clear instructions on how to manage upbound projects in the thoughts/tools folder. up-cli is also installed on this machine. also use its help to populate the content of our docs
- the project is going to be written in kcl, launch an explore agent to deeply research kcl codebase on how to work with kcl, leave your finding in the thoughts/tools folder
- an example of how to build an upbound project with kcl on a little bit bigger complexity can be found here: https://github.com/upbound/platform-ref-upbound/tree/main/functions. Launch an explore agent to deeply research how this module was build, concentrating on the composition functions. Use that to populate the thoughts/coding folder
- launch an agent to populate the thoughts/git folder with instructions on how to do the most common operations like commiting to git, creating a pr and so on and so forth

After this initial discovery finished, create a thoughts/tasks.md file with a full list of all tasks which we need to do to finish this project ORDERED BY PRIORITY  and don't forget to write tha main CLAUDE.md so we know where to pick up our work at any time.

BEFORE you do any of this, leave a file thoughts/initial_prompt.md with this prompt
