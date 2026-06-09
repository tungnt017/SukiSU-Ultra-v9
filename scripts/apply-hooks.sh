#!/bin/bash
set -euo pipefail
OPTIONAL=false; [ "${1:-}" = "--optional" ] && OPTIONAL=true
OK=0; FAIL=0
echo "🔩 SukiSU-Ultra Manual Hook Inserter"
echo ""

echo "📌 Hook 1/5: fs/exec.c"
if [ -f fs/exec.c ] && ! grep -q ksu_handle_execveat fs/exec.c 2>/dev/null; then
  awk '/^int do_execve\(/ && !d { print "#if defined(CONFIG_KSU) && defined(CONFIG_KSU_MANUAL_HOOK)"; print "extern bool ksu_execveat_hook __read_mostly;"; print "extern int ksu_handle_execveat(int *fd, struct filename **filename_ptr, void *argv,"; print "\t\t\tvoid *envp, int *flags);"; print "extern int ksu_handle_execveat_sucompat(int *fd, struct filename **filename_ptr,"; print "\t\t\tvoid *argv, void *envp, int *flags);"; print "#endif"; print ""; d=1 } { print }' fs/exec.c > fs/exec.c.tmp && mv fs/exec.c.tmp fs/exec.c
  awk '/struct user_arg_ptr envp = \{/ && !h { print; getline; print; print "#if defined(CONFIG_KSU) && defined(CONFIG_KSU_MANUAL_HOOK)"; print "\tif (unlikely(ksu_execveat_hook))"; print "\t\tksu_handle_execveat(&AT_FDCWD, &filename, &argv, &envp, 0);"; print "\telse"; print "\t\tksu_handle_execveat_sucompat(&AT_FDCWD, &filename, &argv, &envp, 0);"; print "#endif"; h=1; next } { print }' fs/exec.c > fs/exec.c.tmp && mv fs/exec.c.tmp fs/exec.c
  awk '/^int compat_do_execve\(/ { c=1 } c && /return do_execveat_common/ && !h { print "#if defined(CONFIG_KSU) && defined(CONFIG_KSU_MANUAL_HOOK)"; print "\tif (!ksu_execveat_hook)"; print "\t\tksu_handle_execveat_sucompat(&AT_FDCWD, &filename, &argv, &envp, 0);"; print "#endif"; h=1 } { print }' fs/exec.c > fs/exec.c.tmp && mv fs/exec.c.tmp fs/exec.c
  grep -q ksu_handle_execveat fs/exec.c && { echo "  ✅"; OK=$((OK+1)); } || { echo "  ❌"; FAIL=$((FAIL+1)); }
else
  grep -q ksu_handle_execveat fs/exec.c 2>/dev/null && { echo "  ✅ (exists)"; OK=$((OK+1)); } || { echo "  ❌"; FAIL=$((FAIL+1)); }
fi

echo "📌 Hook 2/5: fs/open.c"
if [ -f fs/open.c ] && ! grep -q ksu_handle_faccessat fs/open.c 2>/dev/null; then
  awk '/SYSCALL_DEFINE3\(faccessat/ && !d { print "#if defined(CONFIG_KSU) && defined(CONFIG_KSU_MANUAL_HOOK)"; print "extern int ksu_handle_faccessat(int *dfd, const char __user **filename_user, int *mode, int *flags);"; print "#endif"; print ""; d=1 } { print }' fs/open.c > fs/open.c.tmp && mv fs/open.c.tmp fs/open.c
  awk '/SYSCALL_DEFINE3\(faccessat/ { f=1 } f && /return do_faccessat/ && !h { print "#if defined(CONFIG_KSU) && defined(CONFIG_KSU_MANUAL_HOOK)"; print "\tksu_handle_faccessat(&dfd, &filename, &mode, NULL);"; print "#endif"; h=1 } { print }' fs/open.c > fs/open.c.tmp && mv fs/open.c.tmp fs/open.c
  grep -q ksu_handle_faccessat fs/open.c && { echo "  ✅"; OK=$((OK+1)); } || { echo "  ❌"; FAIL=$((FAIL+1)); }
else
  grep -q ksu_handle_faccessat fs/open.c 2>/dev/null && { echo "  ✅ (exists)"; OK=$((OK+1)); } || { echo "  ❌"; FAIL=$((FAIL+1)); }
fi

echo "📌 Hook 3/5: fs/read_write.c"
if [ -f fs/read_write.c ] && ! grep -q ksu_handle_sys_read fs/read_write.c 2>/dev/null; then
  awk '/SYSCALL_DEFINE3\(read,/ && !d { print "#if defined(CONFIG_KSU) && defined(CONFIG_KSU_MANUAL_HOOK)"; print "extern bool ksu_vfs_read_hook __read_mostly;"; print "extern int ksu_handle_sys_read(unsigned int fd, char __user **buf, size_t *count);"; print "#endif"; print ""; d=1 } { print }' fs/read_write.c > fs/read_write.c.tmp && mv fs/read_write.c.tmp fs/read_write.c
  awk '/SYSCALL_DEFINE3\(read,/ { f=1 } f && /return ksys_read/ && !h { print "#if defined(CONFIG_KSU) && defined(CONFIG_KSU_MANUAL_HOOK)"; print "\tif (unlikely(ksu_vfs_read_hook))"; print "\t\tksu_handle_sys_read(fd, &buf, &count);"; print "#endif"; h=1 } { print }' fs/read_write.c > fs/read_write.c.tmp && mv fs/read_write.c.tmp fs/read_write.c
  grep -q ksu_handle_sys_read fs/read_write.c && { echo "  ✅"; OK=$((OK+1)); } || { echo "  ❌"; FAIL=$((FAIL+1)); }
else
  grep -q ksu_handle_sys_read fs/read_write.c 2>/dev/null && { echo "  ✅ (exists)"; OK=$((OK+1)); } || { echo "  ❌"; FAIL=$((FAIL+1)); }
fi

echo "📌 Hook 4/5: fs/stat.c"
if [ -f fs/stat.c ] && ! grep -q ksu_handle_stat fs/stat.c 2>/dev/null; then
  awk '/SYSCALL_DEFINE4\(newfstatat/ && !d { print "#if defined(CONFIG_KSU) && defined(CONFIG_KSU_MANUAL_HOOK)"; print "extern int ksu_handle_stat(int *dfd, const char __user **filename_user, int *flags);"; print "#endif"; print ""; d=1 } { print }' fs/stat.c > fs/stat.c.tmp && mv fs/stat.c.tmp fs/stat.c
  awk '/SYSCALL_DEFINE4\(newfstatat/ { f=1 } f && /error = vfs_fstatat/ && !h { print "#if defined(CONFIG_KSU) && defined(CONFIG_KSU_MANUAL_HOOK)"; print "\tksu_handle_stat(&dfd, &filename, &flag);"; print "#endif"; h=1 } { print }' fs/stat.c > fs/stat.c.tmp && mv fs/stat.c.tmp fs/stat.c
  grep -q ksu_handle_stat fs/stat.c && { echo "  ✅"; OK=$((OK+1)); } || { echo "  ❌"; FAIL=$((FAIL+1)); }
else
  grep -q ksu_handle_stat fs/stat.c 2>/dev/null && { echo "  ✅ (exists)"; OK=$((OK+1)); } || { echo "  ❌"; FAIL=$((FAIL+1)); }
fi

echo ""
if [ "$OPTIONAL" = true ]; then
  echo "📌 Hook 5/5: drivers/input/input.c"
  if [ -f drivers/input/input.c ] && ! grep -q ksu_handle_input_handle_event drivers/input/input.c 2>/dev/null; then
    awk '/static void input_handle_event\(/ && !d { print "#if defined(CONFIG_KSU) && defined(CONFIG_KSU_MANUAL_HOOK)"; print "extern void ksu_handle_input_handle_event(unsigned int *type, unsigned int *code, int *value);"; print "#endif"; print ""; d=1 } { print }' drivers/input/input.c > drivers/input/input.c.tmp && mv drivers/input/input.c.tmp drivers/input/input.c
    awk '/int disposition = input_get_disposition/ && !h { print; print "#if defined(CONFIG_KSU) && defined(CONFIG_KSU_MANUAL_HOOK)"; print "\tksu_handle_input_handle_event(&type, &code, &value);"; print "#endif"; h=1; next } { print }' drivers/input/input.c > drivers/input/input.c.tmp && mv drivers/input/input.c.tmp drivers/input/input.c
    grep -q ksu_handle_input_handle_event drivers/input/input.c && { echo "  ✅"; OK=$((OK+1)); } || { echo "  ❌"; FAIL=$((FAIL+1)); }
  else
    grep -q ksu_handle_input_handle_event drivers/input/input.c 2>/dev/null && { echo "  ✅ (exists)"; OK=$((OK+1)); } || { echo "  ❌"; FAIL=$((FAIL+1)); }
  fi
else
  echo "📌 Hook 5/5: SKIPPED (optional)"
fi

echo ""
echo "📊 Summary: ✅ $OK | ❌ $FAIL"
[ $FAIL -gt 0 ] && exit 1 || echo "✅ All hooks OK!"
