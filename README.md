<div align="center"><img src="resources/logo.webp" alt="Datachecker Logo"></div>

**DataChecker** is an open-source command-line tool that helps users save space, fix data and improve security. It is simple, fast and very easy to use.

### Requirements:

- [FreeBSD](https://freebsd.org)
- Linux
- [NetBSD](https://netbsd.org)
- [Windows](https://windows.com)
- ANSI compatible terminal like [kitty](https://sw.kovidgoyal.net/kitty/), xterm, [alacritty](https://alacritty.org), [Cmder](https://cmder.app), [Windows Terminal](https://github.com/microsoft/terminal)

### Download

Binaries for x86_64 are available [here](https://github.com/mazoti/datachecker/tree/main/download). If you don't find a binary release for your system, you can [build from source](#build-from-source).

### Usage

Just run:

```
datachecker <directory>
```

If you want to configure the default behavior, create a default configuration:

```
datachecker config
```

A config.json file will be created in the same folder. If you set the INPUT_FOLDER variable, just run again without any parameter:

```
datachecker
```

Tip: if your results has too many issues, set COLOR and ENTER_TO_QUIT to false and pipe the stderr output:

```
datachecker 2> results.txt
```

## Build from source

### Requirements:

- [FreeBSD](https://freebsd.org): aarch64, arm, powerpc64, powerpc64le, riscv64, x86_64
- Linux: aarch64, arm, loongarch64, powerpc64le, riscv64, s390x, x86, x86_64
- [NetBSD](https://netbsd.org): aarch64, arm, x86, x86_64
- [Windows](https://windows.com): aarch64, x86, x86_64
- [Zig language compiler](https://ziglang.org): the minimal version required could be found in file **build.zig.zon**

NOTE: it was only tested in x86_64.

First download or checkout the source code:

```
git clone --depth=1 https://github.com/mazoti/datachecker
```

Make sure the Zig compiler is in your path:

```
export PATH = <zig directory>:$PATH (Linux or Unix)
set PATH = <zig directory>;%PATH% (Windows)
```

Execute the build command, the binary will be on "bin" folder:

```
zig build -p . --release=fast  (optimize for speed)

                     or

zig build -p . --release=small (optimize for size/power)

                     or

zig build run -- .             (runs in debug mode using current folder)

                     or

zig build test                 (runs unit tests)
```

### Configurations

The following describes the configuration options in the config.json file. If this file does not exist in the same folder as the binary, the system uses the default values.

- Specifies the folder to process. Ignored when a folder is provided as a command-line argument:

      "INPUT_FOLDER": ".",

- Specifies the RAM usage in bytes:

      "BUFFER_SIZE": 65536,

- Shows colored output; disable this if you are piping the output to a file or your terminal is not ANSI compatible:

      "COLOR": true,

- Caches file and folder paths, dates and sizes to improve performance:

      "ENABLE_CACHE": true,

- Displays the message "Press enter to quit" and closes the application only after the user presses Enter:

      "ENTER_TO_QUIT": false,

- Maximum number of threads to use. Leave 0 to automatically use all available CPU threads:

      "MAX_JOBS": 0,

- Duplicate files

  Finds all duplicate files in a folder and displays the total number of wasted bytes. There are two algorithms for this task: a single-threaded two-stage and a parallel three-stage filtering method:

      "DUPLICATE_FILES": true,
          "DUPLICATE_FILES_PARALLEL": true,

- Links and shortcuts

  Finds all shortcuts and symlinks. On Linux and Unix, it also checks whether the target exists:

      "LINKS_SHORTCUTS": true,

- Integrity

  Calculates and verifies file integrity. The following algorithms are supported: Ascon, BLAKE, MD5, and SHA families.
  To calculate a hash, create an empty file in the same folder using the same base name and extension of the target file and append the desired hash extension. Supported hash extensions include:

  - [Ascon](https://ascon.isec.tugraz.at)
    - ascon256

  - [BLAKE](https://github.com/BLAKE3-team/BLAKE3)
    - blake2b128
    - blake2b160
    - blake2b256
    - blake2b384
    - blake2b512
    - blake2s128
    - blake2s160
    - blake2s224
    - blake2s256
    - blake3

  - [MD5](https://www.ietf.org/rfc/rfc1321.txt)
    - md5

  - [SHA](https://csrc.nist.gov/projects/hash-functions)
    - sha1
    - sha224
    - sha256
    - sha256t192
    - sha3_224
    - sha3_256
    - sha3_384
    - sha3_512
    - sha384
    - sha512
    - sha512_224
    - sha512_256
    - sha512t224
    - sha512t256
  

  Example: datachecker.exe.sha256

  When such an empty file is present, DataChecker computes the corresponding hash of the target file and writes the hexadecimal ASCII result into the hash file. If the hash file is not empty, DataChecker instead performs an integrity check by comparing the file's contents with the expected hash value:

      "INTEGRITY_FILES": true,
          "INTEGRITY_FILES_PARALLEL": true,

- Temporary files

  Displays files generated by compilers, browsers, operating systems, servers and databases that are safe to remove:

      "TEMPORARY_FILES": true,

- Confidential files

  Displays files containing confidential data. You can specify any byte array by serializing it with Base64 and inserting it into the PATTERN_BASE64_BYTES array
  or any string by inserting it into the PATTERNS array:

      "CONFIDENTIAL_FILES": true,
        "PATTERNS": [ "access code", "Access code", "Access Code", "ACCESS CODE", ... ],
        "PATTERN_BASE64_BYTES": [
            "LS0tLS1CRUdJTiBEU0EgUFJJVkFURSBLRVktLS0tLQ==",
            "LS0tLS1CRUdJTiBFQyBQUklWQVRFIEtFWS0tLS0t",
            "LS0tLS1CRUdJTiBFTkNSWVBURUQgUFJJVkFURSBLRVktLS0tLQ==",
            "LS0tLS1CRUdJTiBPUEVOU1NIIFBSSVZBVEUgS0VZLS0tLS0=",
            "LS0tLS1CRUdJTiBQUklWQVRFIEtFWS0tLS0t",
            "LS0tLS1CRUdJTiBSU0EgUFJJVkFURSBLRVktLS0tLQ==",
            ...
        ],

- Compressed files

  Displays losslessly compressed files with low compression level or not optimally compressed. You can save space by recompressing them:

      "COMPRESSED_FILES": true,

- Duplicate characters

  Displays duplicate characters such as spaces or underscores in file or directory names:

      "DUPLICATE_CHARS_FILES": true,

- Empty files

  Finds all empty files: in most cases, this is unnecessary or indicates poor programming practice:

      "EMPTY_FILES": true,

- Large files

  Displays all files larger than 100 GB by default. You can change this value by setting the LARGE_FILE_SIZE variable in config.json (value in bytes):

      "LARGE_FILE_SIZE": 107374182400,

- Last access

  Displays all files accessed over a year ago. You can change this value by setting the LAST_ACCESS_TIME variable in config.json (value in nanoseconds):

      "LAST_ACCESS_TIME": 31536000000000000,

- Legacy files

  Displays all files using outdated or unused formats:

      "LEGACY_FILES": true,

- Magic numbers

  Displays all files whose magic number does not match their extension (this can help identify and fix issues):

      "MAGIC_NUMBERS": true,

- No extension

  Displays all files without extension and attempts to identify their file type:

      "NO_EXTENSION": true,

- JSON files

  Displays all JSON files with errors:

      "PARSE_JSON_FILES": true,

- Wrong dates

  Displays all files with access, creation, or modification date in the future:

      "WRONG_DATES": true,

- Empty directories

  Finds all empty folders, which is usually not useful:

      "EMPTY_DIRECTORIES": true,

- Directories with too many items

  Displays all directories containing more than 10,000 items, which could slow down access. You can adjust this threshold by setting the MAX_ITEMS_DIRECTORY value in config.json:

      "MANY_ITEMS_DIRECTORY": true,
        "MAX_ITEMS_DIRECTORY": 10000,

- Directories with one item

  Displays all directories with only one item inside, which is usually not useful:

      "ONE_ITEM_DIRECTORY": true,

- Files and folders with large number of characters in the name

  Different filesystems support different maximum filename lengths in bytes. By default, DataChecker will warn you about any file or folder whose name exceed 200 bytes to ensure portability. You can change this limit by using the MAX_DIR_FILE_NAME_SIZE variable in config.json. Remember that emojis and other UTF-8 characters may take more than 1 byte:

      "DIRECTORY_FILE_NAME_SIZE": true,
        "MAX_DIR_FILE_NAME_SIZE": 200,

- Paths with large number of characters

  Same as above, but checks the absolute path. By default, DataChecker warns you about any file or folder whose path exceed 1024 bytes to ensure portability. You can change this limit using the MAX_FULL_PATH_SIZE variable in config.json:

      "FULL_PATH_SIZE": true,
        "MAX_FULL_PATH_SIZE": 1024,

- Unportable characters

  Displays all files and folders containing characters that are not portable across modern filesystems:

      "UNPORTABLE_CHARS": true

### Donations

Donations of any amount are welcome [here](https://github.com/sponsors/mazoti)

[![License](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)
