#!/bin/bash
# ============================================================
# 🔩 SukiSU-Ultra Manual Hook Inserter (awk-based)
# ============================================================
set -euo pipefail

OPTIONAL=false
if [ "${1:-}" = "--optional" ]; then
  OPTIONAL=true
fi

HOOKS_APPLIED=0
HOOKS_FAILED=0

echo "════════════════════════════════════════════════════"
echo "🔩 SukiSU-Ultra Manual Hook Inserter"
echo "════════════════════════════════════════════════════"
echo ""

# ── Hook 1: fs/exec.c ────────────────────────────────────
echo "📌 Hook 1/5: fs/exec.c (do_execve)"
if [ -f fs/exec.c ] && ! grep -q "ksu_handle_execveat" fs/exec.c 2>/dev/null; then
  awk '
  /^int do_execve\(/ && !done {
    print "#if defined(CONFIG_KSU) && defined(CONFIG_KSU_MANUAL_HOOK)"
    print "extern bool ksu_execveat_hook __read_mostly;"
    print "extern int ksu_handle_execveat(int *fd, struct filename **filename_ptr, void *argv,"
    print "\t\t\tvoid *envp, int *flags);"
    print "extern int ksu_handle_execveat_sucompat(int *fd, struct filename **filename_ptr,"
    print "\t\t\tvoid *argv, void *envp, int *flags);"
    print "#endif"
    print ""
    done=1
  }
  { print }
  ' fs/exec.c > fs/exec.c.tmp && mv fs/exec.c.tmp fs/exec.c

  awk '
  /struct user_arg_ptr envp = \{/ && !hook1_done {
    print
    getline; print
    print "#if defined(CONFIG_KSU) && defined(CONFIG_KSU_MANUAL_HOOK)"
    print "\tif (unlikely(ksu_execveat_hook))"
    print "\t\tksu_handle_execveat(&AT_FDCWD, &filename, &argv, &envp, 0);"
    print "\telse"
    print "\t\tksu_handle_execveat_sucompat(&AT_FDCWD, &filename, &argv, &envp, 0);"
    print "#endif"
    hook1_done=1; next
  }
  { print }
  ' fs/exec.c > fs/exec.c.tmp && mv fs/exec.c.tmp fs/exec.c

  awk '
  /^int compat_do_execve\(/ { in_compat=1 }
  in_compat && /return do_execveat_common/ && !hook2_done {
    print "#if defined(CONFIG_KSU) && defined(CONFIG_KSU_MANUAL_HOOK)"
    print "\tif (unlikely(!ksu_execveat_hook))"
    print "\t\tksu_handle_execveat_sucompat(&AT_FDCWD, &filename, &argv, &envp, 0);"
    print "#endif"
    hook2_done=1
  }
  { print }
  ' fs/exec.c > fs/exec.c.tmp && mv fs/exec.c.tmp fs/exec.c

  grep -q "ksu_handle_execveat" fs/exec.c && { echo "  ✅ Applied"; HOOKS_APPLIED=$((HOOKS_APPLIED+1)); } || { echo "  ❌ Failed"; HOOKS_FAILED=$((HOOKS_FAILED+1)); }
else
  grep -q "ksu_handle_execveat" fs/exec.c 2>/dev/null && { echo "  ℹ️ Already applied"; HOOKS_APPLIED=$((HOOKS_APPLIED+1)); } || { echo "  ❌ Not found"; HOOKS_FAILED=$((HOOKS_FAILED+1)); }
fi

# ── Hook 2: fs/open.c ────────────────────────────────────
echo ""; echo "📌 Hook 2/5: fs/open.c (faccessat)"
if [ -f fs/open.c ] && ! grep -q "ksu_handle_faccessat" fs/open.c 2>/dev/null; then
  awk '/SYSCALL_DEFINE3\(faccessat/ && !d { print "#if defined(CONFIG_KSU) && defined(CONFIG_KSU_MANUAL_HOOK)"; print "extern int ksu_handle_faccessat(int *dfd, const char __user **filename_user, int *mode,"; print "\t\t\tint *flags);"; print "#endif"; print ""; d=1 } { print }' fs/open.c > fs/open.c.tmp && mv fs/open.c.tmp fs/open.c
  awk '/SYSCALL_DEFINE3\(faccessat/ { f=1 } f && /return do_faccessat/ && !h { print "#if defined(CONFIG_KSU) && defined(CONFIG_KSU_MANUAL_HOOK)"; print "\tksu_handle_faccessat(&dfd, &filename, &mode, NULL);"; print "#endif"; h=1 } { print }' fs/open.c > fs/open.c.tmp && mv fs/open.c.tmp fs/open.c
  grep -q "ksu_handle_faccessat" fs/open.c && { echo "  ✅ Applied"; HOOKS_APPLIED=$((HOOKS_APPLIED+1)); } || { echo "  ❌ Failed"; HOOKS_FAILED=$((HOOKS_FAILED+1)); }
else
  grep -q "ksu_handle_faccessat" fs/open.c 2>/dev/null && { echo "  ℹ️ Already applied"; HOOKS_APPLIED=$((HOOKS_APPLIED+1)); } || { echo "  ❌ Not found"; HOOKS_FAILED=$((HOOKS_FAILED+1)); }
fi

# ── Hook 3: fs/read_write.c ──────────────────────────────
echo ""; echo "📌 Hook 3/5: fs/read_write.c (sys_read)"
if [ -f fs/read_write.c ] && ! grep -q "ksu_handle_sys_read" fs/read_write.c 2>/dev/null; then
  awk '/SYSCALL_DEFINE3\(read,/ && !d { print "#if defined(CONFIG_KSU) && defined(CONFIG_KSU_MANUAL_HOOK)"; print "extern bool ksu_vfs_read_hook __read_mostly;"; print "extern int ksu_handle_sys_read(unsigned int fd, char __user **buf, size_t *count);"; print "#endif"; print ""; d=1 } { print }' fs/read_write.c > fs/read_write.c.tmp && mv fs/read_write.c.tmp fs/read_write.c
  awk '/SYSCALL_DEFINE3\(read,/ { f=1 } f && /return ksys_read/ && !h { print "#if defined(CONFIG_KSU) && defined(CONFIG_KSU_MANUAL_HOOK)"; print "\tif (unlikely(ksu_vfs_read_hook))"; print "\t\tksu_handle_sys_read(fd, &buf, &count);"; print "#endif"; h=1 } { print }' fs/read_write.c > fs/read_write.c.tmp && mv fs/read_write.c.tmp fs/read_write.c
  grep -q "ksu_handle_sys_read" fs/read_write.c && { echo "  ✅ Applied"; HOOKS_APPLIED=$((HOOKS_APPLIED+1)); } || { echo "  ❌ Failed"; HOOKS_FAILED=$((HOOKS_FAILED+1)); }
else
  grep -q "ksu_handle_sys_read" fs/read_write.c 2>/dev/null && { echo "  ℹ️ Already applied"; HOOKS_APPLIED=$((HOOKS_APPLIED+1)); } || { echo "  ❌ Not found"; HOOKS_FAILED=$((HOOKS_FAILED+1)); }
fi

# ── Hook 4: fs/stat.c ────────────────────────────────────
echo ""; echo "📌 Hook 4/5: fs/stat.c (newfstatat)"
if [ -f fs/stat.c ] && ! grep -q "ksu_handle_stat" fs/stat.c 2>/dev/null; then
  awk '/SYSCALL_DEFINE4\(newfstatat/ && !d { print "#if defined(CONFIG_KSU) && defined(CONFIG_KSU_MANUAL_HOOK)"; print "extern int ksu_handle_stat(int *dfd, const char __user **filename_user, int *flags);"; print "#endif"; print ""; d=1 } { print }' fs/stat.c > fs/stat.c.tmp && mv fs/stat.c.tmp fs/stat.c
  awk '/SYSCALL_DEFINE4\(newfstatat/ { f=1 } f && /error = vfs_fstatat/ && !h { print "#if defined(CONFIG_KSU) && defined(CONFIG_KSU_MANUAL_HOOK)"; print "\tksu_handle_stat(&dfd, &filename, &flag);"; print "#endif"; h=1 } { print }' fs/stat.c > fs/stat.c.tmp && mv fs/stat.c.tmp fs/stat.c
  grep -q "ksu_handle_stat" fs/stat.c && { echo "  ✅ Applied"; HOOKS_APPLIED=$((HOOKS_APPLIED+1)); } || { echo "  ❌ Failed"; HOOKS_FAILED=$((HOOKS_FAILED+1)); }
else
  grep -q "ksu_handle_stat" fs/stat.c 2>/dev/null && { echo "  ℹ️ Already applied"; HOOKS_APPLIED=$((HOOKS_APPLIED+1)); } || { echo "  ❌ Not found"; HOOKS_FAILED=$((HOOKS_FAILED+1)); }
fi

# ── Hook 5 (optional): drivers/input/input.c ─────────────
echo ""
if [ "$OPTIONAL" = true ]; then
  echo "📌 Hook 5/5: drivers/input/input.c (Safe Mode)"
  if [ -f drivers/input/input.c ] && ! grep -q "ksu_handle_input_handle_event" drivers/input/input.c 2>/dev/null; then
    awk '/static void input_handle_event\(/ && !d { print "#if defined(CONFIG_KSU) && defined(CONFIG_KSU_MANUAL_HOOK)"; print "extern void ksu_handle_input_handle_event(unsigned int *type, unsigned int *code, int *value);"; print "#endif"; print ""; d=1 } { print }' drivers/input/input.c > drivers/input/input.c.tmp && mv drivers/input/input.c.tmp drivers/input/input.c
    awk '/int disposition = input_get_disposition/ && !h { print; print "#if defined(CONFIG_KSU) && defined(CONFIG_KSU_MANUAL_HOOK)"; print "\tksu_handle_input_handle_event(&type, &code, &value);"; print "#endif"; h=1; next } { print }' drivers/input/input.c > drivers/input/input.c.tmp && mv drivers/input/input.c.tmp drivers/input/input.c
    grep -q "ksu_handle_input_handle_event" drivers/input/input.c && { echo "  ✅ Applied"; HOOKS_APPLIED=$((HOOKS_APPLIED+1)); } || { echo "  ❌ Failed"; HOOKS_FAILED=$((HOOKS_FAILED+1)); }
  else
    grep -q "ksu_handle_input_handle_event" drivers/input/input.c 2>/dev/null && { echo "  ℹ️ Already applied"; HOOKS_APPLIED=$((HOOKS_APPLIED+1)); } || { echo "  ❌ Not found"; HOOKS_FAILED=$((HOOKS_FAILED+1)); }
  fi
else
  echo "📌 Hook 5/5: drivers/input/input.c — SKIPPED (optional)"
fi

echo ""
echo "════════════════════════════════════════════════════"
echo "📊 Hook Summary: ✅ $HOOKS_APPLIED applied, ❌ $HOOKS_FAILED failed"
echo "════════════════════════════════════════════════════"

if [ $HOOKS_FAILED -gt 0 ]; then
  echo "⚠️ Some hooks failed!"
  exit 1
else
  echo "✅ All hooks applied successfully!"
fi
