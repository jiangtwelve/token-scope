#!/usr/bin/env sh
set -eu

root="${1:-.}"
status=0

need_file() {
  if [ ! -f "$root/$1" ]; then
    printf 'missing file: %s\n' "$1"
    status=1
  fi
}

required_files="AGENTS.md CLAUDE.md .project-governance/AGENT_BOOTSTRAP.md .project-governance/rules/GRILLING_PROTOCOL.md .project-governance/rules/DEVELOPMENT_PROCESS.md .project-governance/rules/VERSION_RULES.md .project-governance/rules/DOCUMENTATION_RULES.md .project-governance/rules/UPGRADE_RULES.md .project-governance/processes/active.md .project-governance/ssot/PROJECT_STATE.md .project-governance/ssot/PRD.md .project-governance/ssot/ARCHITECTURE.md .project-governance/ssot/API_CONTRACT.md .project-governance/ssot/GLOSSARY.md .project-governance/decisions/INDEX.md .project-governance/imports/SOURCE_INDEX.md .project-governance/templates/RECORD_TEMPLATES.md"

for file in $required_files; do
  need_file "$file"
done

if [ -f "$root/AGENTS.md" ] && ! grep -q 'project-governance:start' "$root/AGENTS.md"; then
  printf 'AGENTS.md missing project-governance marker block\n'
  status=1
fi

if [ -f "$root/CLAUDE.md" ] && ! grep -q 'project-governance:start' "$root/CLAUDE.md"; then
  printf 'CLAUDE.md missing project-governance marker block\n'
  status=1
fi

state_file="$root/.project-governance/ssot/PROJECT_STATE.md"
if [ -f "$state_file" ]; then
  for section in "## Active Version" "## Versions" "## Stage Regressions" "## Stage Skips" "## Backlog"; do
    if ! grep -qF "$section" "$state_file"; then
      printf 'PROJECT_STATE.md missing section: %s\n' "$section"
      status=1
    fi
  done
fi

if [ "$status" -eq 0 ]; then
  printf 'project-governance structure OK\n'
fi

exit "$status"
