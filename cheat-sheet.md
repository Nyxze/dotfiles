## Bash

Create 'x' files :

```bash
touch file_name-{1..x}
```

Get current directory:

```bash
work_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd )
```

### Array syntax
Array loop:

```bash
    for f in "${array[@]}"; do
    done
```

Array length:

```bash
len=${#array[@]}
```