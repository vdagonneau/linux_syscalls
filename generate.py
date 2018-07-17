#!/usr/bin/env python3

import json
import os
from jinja2 import Environment, FileSystemLoader

tags = None
with open('site/data/tags.json') as f:
  tags = json.load(f)

env = Environment(
    loader=FileSystemLoader('templates'),
)

kernel_tpl = env.get_template('kernel.html')

for tag in tags:
  if os.path.isfile('site/kernel-{}.html'.format(tag)):
    print("Static file site/kernel-{}.html is already present; Skipping ...".format(tag))
    continue

  if not os.path.isfile('site/data/syscalls-{}.json'.format(tag)):
    print("No JSON data available for version {}; Skipping ...".format(tag))
    continue

  print("Generating static page for version {}.".format(tag))
  raw_syscalls = None
  with open('site/data/syscalls-{}.json'.format(tag), 'r') as f:
    raw_syscalls = json.load(f)

  syscalls = []
  for syscall in raw_syscalls:
    args = syscall['name'].split(',')
    s = { 'name': args.pop(0) }
    s['args'] = []
    while len(args) > 1:
      s['args'].append({ 'type': args.pop(0), 'name': args.pop(0) })

    syscalls.append(s)

  with open('site/kernel-{}.html'.format(tag), 'w+') as f:
    f.write(kernel_tpl.render({ 'tag': tag, 'syscalls': syscalls }))

index_tpl = env.get_template('index.html')
with open('site/index.html', 'w+') as f:
  f.write(index_tpl.render({ 'tags': tags }))
