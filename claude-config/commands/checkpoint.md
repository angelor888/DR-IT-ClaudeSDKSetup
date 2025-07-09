# Git Checkpoint Command

I'll help you create a Git checkpoint for your recent changes.

## Current Status Check

Let me first check the current state of your repository:

```bash
git status
git diff --stat
```

## Checkpoint Creation

Based on the changes, I'll:

1. **Review Changes**: Show you what will be committed
2. **Suggest Commit Message**: Based on the changes made
3. **Create Checkpoint**: Add and commit the changes
4. **Confirm Success**: Verify the commit was created

## Commit Message Template

I'll use this format for the commit message:
```
{action}: {description}

{details}

🤖 Generated with Claude Code
Co-Authored-By: Claude <noreply@anthropic.com>
```

## Rollback Instructions

If you need to undo this checkpoint later:
- **Soft reset**: `git reset --soft HEAD~1` (keeps changes staged)
- **Hard reset**: `git reset --hard HEAD~1` (removes changes completely)
- **Revert commit**: `git revert HEAD` (creates new commit that undoes changes)

Would you like me to proceed with creating the checkpoint?