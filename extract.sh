#!/bin/bash

KERNEL_GIT_URL='git://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git'
SYSCALL_REGEX='SYSCALL_DEFINE[0-9]{1}\(\K([^,)]+(\,[^,)]+)*)'
KERNEL_EXCLUDES="--exclude-dir=arch --exclude-dir=include --exclude-dir=.git --exclude-dir=Documentation"

if [ ! -d "linux" ]; then
    echo "Directory 'linux' does not exist. Cloning linux kernel sources from \
         ${KERNEL_GIT_URL}. This may take a lot of time!"
    git clone ${KERNEL_GIT_URL}
else
    echo "Directory 'linux' exists. Skipping the cloning of the kernel sources."
fi

cd linux

ttxt="["
tag_list=$(git tag --sort=v:refname | tac)
for tag in ${tag_list}; do
  if [[ ${tag} = *"rc"* ]]; then
    echo "Version ${tag} is a release candidate; Skipping ..."
    continue
  fi

  if [ -f "../data/syscalls-${tag}.json" ]; then
    echo "Syscall data already present for version ${tag}; Skipping ..."
    continue
  fi

  ttxt="${ttxt}\"${tag}\","

  echo "Checking out kernel sources for version ${tag}."
  git checkout ${tag}

  syscalls=$(grep -Po -r ${KERNEL_EXCLUDES} "${SYSCALL_REGEX}" . | cut -f2 -d":"|sort -u)
  echo "Scanned kernel sources; Found $(echo "${syscalls}"|wc -l) uniq syscalls."

  stxt='['
  while read -r syscall; do
    stxt="${stxt} { \"name\": \"${syscall}\" },"
  done <<< "$syscalls"
  stxt=${stxt::-1}
  stxt="${stxt}]"

  echo "${stxt}" > ../site/data/syscalls-${tag}.json
done
ttxt=${ttxt::-1}
ttxt="${ttxt}]"

echo "${ttxt}" > ../site/data/tags.json
