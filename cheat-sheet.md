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

String lengh

```bash
stringZ=yolo
len= ${#stringZ} # 3

```
Substring

```bash
stringZ= yolo123
echo ${stringZ#123} # yolo

```

Replace:
```bash
echo ${stringZ/abc/xyz}       # xyzABC123ABCabc
echo ${stringZ//abc/xyz}      # xyzABC123ABCxyz
                              # Replaces all matches of 'abc' with # 'xyz'.
echo  ---------------
echo "$stringZ"               # abcABC123ABCabc
echo  ---------------
                              # The string itself is not altered!
```
