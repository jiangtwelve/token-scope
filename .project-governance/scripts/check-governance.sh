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

# Advisory: 仅提示，不改 exit code。
# 当 active.md 中存在 acceptance_required: true 阶段，且对应 task plan 文件缺失时给出提醒。
# 对已存在 task plan 做轻量格式提醒：必须包含 Review Log 及其固定表头。
active_file="$root/.project-governance/processes/active.md"
tasks_dir="$root/.project-governance/processes/tasks"
if [ -f "$active_file" ]; then
  grep -E '^- id: [a-zA-Z0-9_-]+$' "$active_file" | awk '{print $3}' | while IFS= read -r stage_id; do
    [ -z "$stage_id" ] && continue
    ctx=$(grep -A 6 "^- id: ${stage_id}$" "$active_file" | grep "acceptance_required:" | head -1)
    case "$ctx" in
      *"true"*)
        plan_files=$(ls "$tasks_dir"/${stage_id}*.md 2>/dev/null || true)
        if [ -z "$plan_files" ]; then
          printf 'advisory: acceptance_required stage "%s" has no task plan in processes/tasks/ yet\n' "$stage_id"
        else
          for plan_file in $plan_files; do
            if ! grep -qF '## Review Log' "$plan_file"; then
              printf 'advisory: task plan "%s" missing required Review Log section\n' "$plan_file"
            fi
            if ! grep -qF '| Date | Scope | Result | Findings | Fix Status | Review Method |' "$plan_file"; then
              printf 'advisory: task plan "%s" missing fixed Review Log table header\n' "$plan_file"
            fi
          done
        fi
        ;;
    esac
  done
fi

if [ "$status" -eq 0 ]; then
  printf 'project-governance structure OK\n'
fi

exit "$status"
