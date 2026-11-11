//!
//!
//!
//!
//!
//! Copyright © 2025-present Marcos Mazoti

const std = @import("std");

/// Array of substrings that indicate temporary files when found anywhere in the path
/// These patterns identify version control, build artifacts, and system temporary locations
pub const CONTAINS = [_][]const u8{
    "\\$Recycle.bin\\",
    "\\AppData\\Local\\Temp",
    "\\Windows\\Temp",
    "\\AppData\\Local\\Microsoft\\INetCache\\IE",
    "\\AppData\\Local\\Microsoft\\INetCache\\Content.IE5",
    ".~lock.",                                     // LibreOffice/OpenOffice lock files prevent concurrent editing
    ".git/objects/tmp_",                           // Git creates tmp_* during object creation (Unix)
    ".git\\objects\\tmp_",                         // Git creates tmp_* during object creation (Windows)
    ".hg/store/journal",                           // Mercurial transaction journal (Unix)
    ".hg\\store\\journal",                         // Mercurial transaction journal (Windows)
    ".svn/tmp/",                                   // Subversion working copy temp area (Unix)
    ".svn\\tmp\\",                                 // Subversion working copy temp area (Windows)
    ".torrent.",                                   // Torrent metadata/partial files
    "/tmp/",                                       // Standard Unix temp directory
    "\\tmp\\",                                     // Windows temp directory
    "/node_modules/",                              // npm dependencies - massive directory, often excluded (Unix)
    "\\node_modules\\",                            // npm dependencies
    "/pycache/",                                   // Python bytecode cache
    "\\pycache\\",                                 // Python bytecode cache
    "__pycache__",                                 // Python bytecode cache
    "/logs/",                                      // Logs directory
    "\\logs\\",                                    // Logs directory
    "/.pyre/",                                     // Pyre’s working data
    "\\.pyre\\",                                   // Pyre’s working data
    "/.mypy_cache/",                               // mypy's cache results
    "\\.mypy_cache\\",                             // mypy's cache results
    "/.pytest_cache/",                             // Python testing framework cache folder
    "\\.pytest_cache\\",                           // Python testing framework cache folder
    "/.hypothesis/",                               // Hypothesis testing library folder
    "\\.hypothesis\\",                             // Hypothesis testing library folder
    "/.nox/",                                      // Nox automating tests folder
    "\\.nox\\",                                    // Nox automating tests folder
    "/.tox/",                                      // Tox automating tests folder
    "\\.tox\\",                                    // Tox automating tests folder
    "/htmlcov/",                                   // coverage.py’s HTML report
    "\\htmlcov\\",                                 // coverage.py’s HTML report
    "/build/",
    "\\build\\",
    "/dist/",
    "\\dist\\",
    "/eggs/",
    "\\eggs\\",
    "/.eggs/",
    "\\.eggs\\",
    "/develop-eggs/",
    "\\develop-eggs\\",
    ".egg-info/",
    ".egg-info\\",
    "/.ipynb_checkpoints/",
    "\\.ipynb_checkpoints\\",
    ".coverage.",
};

/// Map of exact filenames to their descriptions for system-generated temporary files
pub const FULL_NAME = std.StaticStringMap([]const u8).initComptime(.{
    .{ ".DS_Store"                     , ""                                   },
    .{ "desktop.ini"                   , ""                                   },
    .{ "ehthumbs.db"                   , "Windows thumbnail cache (enhanced)" },
    .{ "hiberfil.sys"                  , ""                                   },
    .{ "Thumbs.db"                     , "Windows thumbnail cache"            },
    .{ "THUMBS.DB"                     , "Windows thumbnail cache"            },
    .{ "distutils.log"                 , ""                                   },
    .{ "pip-log.txt"                   , ""                                   },
    .{ "pip-delete-this-directory.txt" , ""                                   },
    .{ "nosetests.xml"                 , "xUnit test results"                 },
    .{ "coverage.xml"                  , "Cobertura coverage report"          },
    .{ ".python-version"               , ""                                   },
    .{ ".dmypy.json"                   , ""                                   },
});

/// Map of legacy/obsolete file extensions to their descriptions
/// Contains formats from older software, operating systems, and file formats
pub const LEGACY_EXTENSIONS_DESCRIPTION = std.StaticStringMap([]const u8).initComptime(.{
    .{ ".123"                 , "Lotus 1-2-3"                          },
    .{ ".669"                 , "Composer 669"                         },
    .{ ".8svx"                , "Amiga 8-bit sound"                    },
    .{ ".adf"                 , "Amiga Disk File"                      },
    .{ ".aiff"                , "Audio Interchange File Format"        },
    .{ ".arc"                 , "ARC archive"                          },
    .{ ".arj"                 , "ARJ compressed archive"               },
    .{ ".asf"                 , "Advanced Systems Format"              },
    .{ ".au"                  , "Sun Audio file"                       },
    .{ ".b64"                 , "Base64 encoded"                       },
    .{ ".bas"                 , "BASIC source code"                    },
    .{ ".bat"                 , "Batch file"                           },
    .{ ".binhex"              , "BinHex encoded"                       },
    .{ ".bmp"                 , "Bitmap"                               },
    .{ ".cgm"                 , "Computer Graphics Metafile"           },
    .{ ".cmf"                 , "Creative Music File"                  },
    .{ ".com"                 , "DOS executable"                       },
    .{ ".cut"                 , "Dr. Halo"                             },
    .{ ".cwk"                 , "ClarisWorks document"                 },
    .{ ".d64"                 , "Commodore 64 disk"                    },
    .{ ".dbf"                 , "dBASE database file"                  },
    .{ ".dif"                 , "Data Interchange Format"              },
    .{ ".dl"                  , "DL Animation"                         },
    .{ ".doc"                 , "Microsoft Word 97-2003"               },
    .{ ".dsk"                 , "Disk image"                           },
    .{ ".dxf"                 , "AutoCAD exchange"                     },
    .{ ".ez"                  , "Andrew Toolkit Document"              },
    .{ ".far"                 , "Farandole Composer"                   },
    .{ ".fdi"                 , "Formatted Disk Image"                 },
    .{ ".fla"                 , "Adobe Flash source"                   },
    .{ ".flc"                 , "Autodesk Animator"                    },
    .{ ".fli"                 , "Autodesk Animator"                    },
    .{ ".fon"                 , "Font file"                            },
    .{ ".frm"                 , "FoxPro form"                          },
    .{ ".gem"                 , "GEM Metafile"                         },
    .{ ".gl"                  , "Grasp GL"                             },
    .{ ".grp"                 , "Program Group"                        },
    .{ ".hqx"                 , "BinHex - Mac"                         },
    .{ ".iff"                 , "Interchange File Format - Amiga"      },
    .{ ".ima"                 , "Disk image"                           },
    .{ ".it"                  , "Impulse Tracker"                      },
    .{ ".jpeg"                , "Joint Photographic Experts Group"     },
    .{ ".jpg"                 , "Joint Photographic Experts Group"     },
    .{ ".lbm"                 , "Deluxe Paint"                         },
    .{ ".lha"                 , "LHArc"                                },
    .{ ".lzh"                 , "LZH compressed archive"               },
    .{ ".manuscript"          , "WriteNow"                             },
    .{ ".mcw"                 , "MacWrite"                             },
    .{ ".mdb"                 , "Microsoft Access Database"            },
    .{ ".mdx"                 , "Multiple index"                       },
    .{ ".mid"                 , "Musical Instrument Digital Interface" },
    .{ ".midi"                , "Musical Instrument Digital Interface" },
    .{ ".mime"                , "MIME encoded"                         },
    .{ ".mov"                 , "QuickTime movie"                      },
    .{ ".msp"                 , "Microsoft Paint"                      },
    .{ ".mtm"                 , "MultiTracker"                         },
    .{ ".nb"                  , "Nota Bene"                            },
    .{ ".ndx"                 , "dBASE index"                          },
    .{ ".ntx"                 , "Clipper index"                        },
    .{ ".nuv"                 , "NuppelVideo"                          },
    .{ ".ovl"                 , "Overlay file"                         },
    .{ ".pak"                 , "PAK archive"                          },
    .{ ".pas"                 , "Pascal source code"                   },
    .{ ".pct"                 , "PICT image"                           },
    .{ ".pcx"                 , "PC Paintbrush image"                  },
    .{ ".pfr"                 , "Portable Font Resource"               },
    .{ ".pic"                 , "PC Paint/Pictor"                      },
    .{ ".pif"                 , "Program Information File"             },
    .{ ".pit"                 , "PackIt archive - Mac"                 },
    .{ ".plt"                 , "HPGL plotter"                         },
    .{ ".prg"                 , "dBASE program"                        },
    .{ ".psw"                 , "Pocket Word"                          },
    .{ ".pwl"                 , "Password List"                        },
    .{ ".pxl"                 , "Pocket Excel"                         },
    .{ ".qpd"                 , "Quattro Pro"                          },
    .{ ".ra"                  , "RealAudio"                            },
    .{ ".rm"                  , "RealMedia file"                       },
    .{ ".rol"                 , "AdLib ROL file"                       },
    .{ ".rtf"                 , "Rich Text Format"                     },
    .{ ".s3m"                 , "ScreamTracker 3"                      },
    .{ ".sam"                 , "Samna Word"                           },
    .{ ".scr"                 , "Screen saver"                         },
    .{ ".scx"                 , "FoxPro screen"                        },
    .{ ".sdw"                 , "StarOffice Writer document"           },
    .{ ".sgi"                 , "Silicon Graphics Image"               },
    .{ ".sit"                 , "StuffIt archive"                      },
    .{ ".snd"                 , "Sound file"                           },
    .{ ".sqz"                 , "Squeeze"                              },
    .{ ".sun"                 , "Sun Raster"                           },
    .{ ".sylk"                , "Symbolic Link"                        },
    .{ ".targa"               , "TARGA image"                          },
    .{ ".td0"                 , "Teledisk"                             },
    .{ ".tga"                 , "TARGA image"                          },
    .{ ".tiff"                , "Tagged Image File Format"             },
    .{ ".tsr"                 , "Terminate and Stay Resident"          },
    .{ ".ult"                 , "Ultra Tracker"                        },
    .{ ".uue"                 , "UUEncoded"                            },
    .{ ".voc"                 , "Creative Voice File"                  },
    .{ ".wav"                 , "Waveform Audio File Format"           },
    .{ ".wk1"                 , "Lotus 1-2-3 spreadsheet"              },
    .{ ".wk3"                 , "Lotus 1-2-3 spreadsheet"              },
    .{ ".wk4"                 , "Lotus 1-2-3 spreadsheet"              },
    .{ ".wks"                 , "Microsoft Works spreadsheet"          },
    .{ ".wmf"                 , "Windows Metafile"                     },
    .{ ".wmv"                 , "Windows Media Video"                  },
    .{ ".wpd"                 , "WordPerfect Document"                 },
    .{ ".wpg"                 , "WordPerfect Graphics"                 },
    .{ ".wps"                 , "Microsoft Works Word Processor"       },
    .{ ".wri"                 , "Windows Write"                        },
    .{ ".xls"                 , "Microsoft Excel 97-2003"              },
    .{ ".xm"                  , "FastTracker 2"                        },
    .{ ".xy"                  , "XyWrite"                              },
    .{ ".yuv"                 , "Raw YUV video"                        },
    .{ ".zoo"                 , "ZOO compressed archive"               },
});

pub const MAGIC_NUMBERS = std.StaticStringMap([]const u8).initComptime(.{
    .{ ".7z"         , "\x37\x7A\xBC\xAF\x27\x1C"                                          }, // 7-Zip archive
    .{ ".bmp"        , "\x42\x4D"                                                          }, // Windows Bitmap
    .{ ".bz2"        , "\x42\x5A\x68"                                                      }, // BZIP2 compressed file
    .{ ".cab"        , "\x4D\x53\x43\x46"                                                  }, // Microsoft Cabinet file
    .{ ".cbor"       , "\xD9\xD9\xF7"                                                      }, // Concise Binary Object Representation
    .{ ".class"      , "\xCA\xFE\xBA\xBE"                                                  }, // Java compiled class file
    .{ ".chm"        , "\x49\x54\x53\x46\x03\x00\x00\x00"                                  }, // Compiled HTML Help
    .{ ".db"         , "\x53\x51\x4C\x69\x74\x65\x20\x66\x6F\x72\x6D\x61\x74\x20\x33\x00"  }, // SQLite database
    .{ ".dll"        , "\x4D\x5A"                                                          }, // Windows Dynamic Link Library
    .{ ".doc"        , "\xD0\xCF\x11\xE0\xA1\xB1\x1A\xE1"                                  }, // Microsoft Word Document
    .{ ".elf"        , "\x7F\x45\x4C\x46"                                                  }, // Linux Executable and Linkable Format (.elf DOES NOT EXISTS)
    .{ ".exe"        , "\x4D\x5A"                                                          }, // Windows Portable Executable
    .{ ".ez"         , "\\begindata{"                                                      }, // Andrew Toolkit Document
    .{ ".flac"       , "\x66\x4C\x61\x43\x00\x00\x00\x22"                                  }, // Free Lossless Audio Codec
    .{ ".gz"         , "\x1F\x8B"                                                          }, // GZIP compressed file
    .{ ".ico"        , "\x00\x00\x01\x00"                                                  }, // Windows Icon
    .{ ".jpg"        , "\xFF\xD8\xFF"                                                      }, // JPEG image files
    .{ ".lnk"        , "\x4C\x00\x00\x00"                                                  }, // Windows shortcut
    .{ ".m3u8"       , "#EXTM3U"                                                           }, // UTF-8 encoded playlist
    .{ ".mds"        , "MEDIA DESCRIPTOR\x00\x03\x00\x01\x00"                              }, // Media Descriptor File
    .{ ".ogg"        , "\x4F\x67\x67\x53"                                                  }, // Ogg multimedia container
    .{ ".pdf"        , "\x25\x50\x44\x46"                                                  }, // Portable Document Format
    .{ ".png"        , "\x89\x50\x4E\x47\x0D\x0A\x1A\x0A"                                  }, // Portable Network Graphics
    .{ ".ppt"        , "\xD0\xCF\x11\xE0\xA1\xB1\x1A\xE1"                                  }, // Microsoft PowerPoint
    .{ ".ps"         , "\x25\x21\x50\x53"                                                  }, // PostScript document
    .{ ".psd"        , "\x38\x42\x50\x53"                                                  }, // Adobe Photoshop Document
    .{ ".rar"        , "\x52\x61\x72\x21\x1A\x07\x01\x00"                                  }, // RAR archive
    .{ ".rtf"        , "\x7B\x5C\x72\x74\x66\x31"                                          }, // Rich Text Format
    .{ ".svg"        , "\x3C\x73\x76\x67"                                                  }, // Scalable Vector Graphics
    .{ ".ttf"        , "\x00\x01\x00\x00"                                                  }, // TrueType Font
    .{ ".utf8bom"    , "\xEF\xBB\xBF"                                                      }, // UTF-8 Byte Order Mark (Does not exists .utf8bom)
    .{ ".utf16bebom" , "\xFE\xFF"                                                          }, // UTF-16 Big Endian BOM (Does not exists .utf16bebom)
    .{ ".utf16lebom" , "\xFF\xFE"                                                          }, // UTF-16 Little Endian BOM (Does not exists .utf16lebom)
    .{ ".xml"        , "\x3C\x3F\x78\x6D\x6C"                                              }, // XML document
    .{ ".woff"       , "\x77\x4F\x46\x46"                                                  }, // Web Open Font Format
});

pub const MAGIC_NUMBERS_KEY = std.StaticStringMap([]const u8).initComptime(.{
    .{ "\\begindata{"                                                     , ".ez"          }, // Andrew Toolkit Document
    .{ "#EXTM3U"                                                          , ".m3u8"        }, // UTF-8 encoded playlist
    .{ "MEDIA DESCRIPTOR\x00\x03\x00\x01\x00"                             , ".mds"         }, // Media Descriptor File
    .{ "\x00\x00\x01\x00"                                                 , ".ico"         }, // Windows Icon
    .{ "\x00\x01\x00\x00"                                                 , ".ttf"         }, // TrueType Font
    .{ "\x1F\x8B"                                                         , ".gz"          }, // GZIP compressed file
    .{ "\x25\x21\x50\x53"                                                 , ".ps"          }, // PostScript document
    .{ "\x25\x50\x44\x46"                                                 , ".pdf"         }, // Portable Document Format
    .{ "\x37\x7A\xBC\xAF\x27\x1C"                                         , ".7z"          }, // 7-Zip archive
    .{ "\x38\x42\x50\x53"                                                 , ".psd"         }, // Adobe Photoshop Document
    .{ "\x3C\x3F\x78\x6D\x6C"                                             , ".xml"         }, // XML document
    .{ "\x3C\x73\x76\x67"                                                 , ".svg"         }, // Scalable Vector Graphics
    .{ "\x42\x4D"                                                         , ".bmp"         }, // Windows Bitmap
    .{ "\x42\x5A\x68"                                                     , ".bz2"         }, // BZIP2 compressed file
    .{ "\x49\x54\x53\x46\x03\x00\x00\x00"                                 , ".chm"         }, // Compiled HTML Help
    .{ "\x4C\x00\x00\x00"                                                 , ".lnk"         }, // Windows shortcut
    .{ "\x4D\x53\x43\x46"                                                 , ".cab"         }, // Microsoft Cabinet file
    .{ "\x4D\x5A"                                                         , ".dll/exe"     }, // Windows Dynamic Link Library/Windows Portable Executable
    .{ "\x4F\x67\x67\x53"                                                 , ".ogg"         }, // Ogg multimedia container
    .{ "\x52\x61\x72\x21\x1A\x07\x01\x00"                                 , ".rar"         }, // RAR archive
    .{ "\x53\x51\x4C\x69\x74\x65\x20\x66\x6F\x72\x6D\x61\x74\x20\x33\x00" , ".db"          }, // SQLite database
    .{ "\x66\x4C\x61\x43\x00\x00\x00\x22"                                 , ".flac"        }, // Free Lossless Audio Codec
    .{ "\x77\x4F\x46\x46"                                                 , ".woff"        }, // Web Open Font Format
    .{ "\x7B\x5C\x72\x74\x66\x31"                                         , ".rtf"         }, // Rich Text Format
    .{ "\x7F\x45\x4C\x46"                                                 , "elf"          }, // Linux Executable and Linkable Format (.elf DOES NOT EXISTS)
    .{ "\x89\x50\x4E\x47\x0D\x0A\x1A\x0A"                                 , ".png"         }, // Portable Network Graphics
    .{ "\xCA\xFE\xBA\xBE"                                                 , ".class"       }, // Java compiled class file
    .{ "\xD0\xCF\x11\xE0\xA1\xB1\x1A\xE1"                                 , ".doc/ppt/xls" }, // Microsoft Word/PowerPoint/XML Document
    .{ "\xD9\xD9\xF7"                                                     , ".cbor"        }, // Concise Binary Object Representation
    .{ "\xEF\xBB\xBF"                                                     , ".utf8bom"     }, // UTF-8 Byte Order Mark (Does not exists .utf8bom)
    .{ "\xFE\xFF"                                                         , ".utf16bebom"  }, // UTF-16 Big Endian BOM (Does not exists .utf16bebom)
    .{ "\xFF\xD8\xFF"                                                     , ".jpg"         }, // JPEG image files
    .{ "\xFF\xFE"                                                         , ".utf16lebom"  }, // UTF-16 Little Endian BOM (Does not exists .utf16lebom)
});

const StartEndPattern = struct { start: []const u8, end: []const u8 };

/// Dual-condition pattern matcher for filename prefix/suffix combinations
/// Allows matching files like "~*.docx" (temp Word files) or "*~" (backup files)
/// Empty string means "no constraint" - enabling prefix-only or suffix-only matching
pub const START_END = [_]StartEndPattern{
    .{ .start = "."            , .end = ""                             }, // Unix hidden files
    .{ .start = ".#"           , .end = ""                             }, // Emacs lock files (#.#filename)
    .{ .start = ".$"           , .end = ""                             }, // Temp file marker
    .{ .start = ".fuse_hidden" , .end = ""                             }, // FUSE kernel filesystem hidden files
    .{ .start = ".nfs"         , .end = ""                             }, // Network File System temp files (prevent deletion while open)
    .{ .start = ".z"           , .end = ""                             }, // Compressed temp files
    .{ .start = ""             , .end = "~"                            }, // *~ backup files (emacs, vim, gedit)
    .{ .start = "#"            , .end = "#"                            }, // #file# Emacs auto-save pattern
    .{ .start = "~"            , .end = ""                             }, // ~file backup files
    .{ .start = "~"            , .end = ".docx"                        }, // ~file.docx Word temporary
    .{ .start = "~$."          , .end = ""                             }, // ~$.file Office owner files
    .{ .start = "~$"           , .end = ".pptx"                        }, // ~$presentation.pptx PowerPoint temp
    .{ .start = "temp"         , .end = ""                             }, // temp* naming convention
    .{ .start = "tmp"          , .end = ""                             }, // tmp* naming convention
};

/// Map of file extensions to descriptions for temporary and cache files
/// Covers a wide range of temporary files from various applications and systems
pub const TEMPORARY_EXTENSIONS = std.StaticStringMap([]const u8).initComptime(.{
    // System metadata and cache
    .{ "._.ds_store"          , "MacOS directory metadata"             },
    .{ ".~tmp"                , ""                                     },
    .{ ".$$$"                 , ""                                     },
    .{ ".$$tmp"               , ""                                     },
    .{ ".autosave"            , "Auto-saved documents"                 },
    .{ ".cache"               , "Cached data files"                    },
    .{ ".chk"                 , "Disk check fragments"                 },
    .{ ".dmp"                 , "Memory dump files"                    },
    .{ ".ds_store"            , "MacOS directory metadata"             },
    .{ ".ffs_tmp"             , "FreeFileSync"                         },
    .{ ".frm"                 , "MySQL table format"                   },
    .{ ".fseventsd"           , "MacOS file system events"             },
    .{ ".ftg"                 , "Help full-text search"                },
    .{ ".gid"                 , "Help index"                           },
    .{ ".gvfs"                , "GNOME Virtual File System"            },
    .{ ".iceauthority"        , "X11 ICE authentication"               },
    .{ ".localized"           , "MacOS folder localization"            },
    .{ ".mdmp"                , "Crash dumps"                          },
    .{ ".myd"                 , "MySQL temp"                           },
    .{ ".myi"                 , "MySQL index files"                    },
    .{ ".ncb"                 , "Visual C++ IntelliSense"              },
    .{ ".old"                 , "Old versions of files"                },
    .{ ".orig"                , "Merge conflict originals"             },
    .{ ".peak"                , "Audio waveform cache"                 },
    .{ ".pf"                  , "Windows prefetch files"               },
    .{ ".pid"                 , "Process ID files"                     },
    .{ ".recently-used"       , "GTK recent files list"                },
    .{ ".recovery"            , "Firefox"                              },
    .{ ".rej"                 , "Patch reject files"                   },
    .{ ".sample"              , "GitHub example"                       },
    .{ ".scc"                 , "Scene cache"                          },
    .{ ".spotlight-v100"      , "MacOS Spotlight index"                },
    .{ ".suo"                 , "Visual Studio user options"           },
    .{ ".swap"                , ""                                     },
    .{ ".swo"                 , "Vim editor swap files"                },
    .{ ".swp"                 , ""                                     },
    .{ ".t"                   , ""                                     },
    .{ ".t$m"                 , ""                                     },
    .{ ".temp"                , ""                                     },
    .{ ".temporary"           , ""                                     },
    .{ ".temporaryitems"      , ""                                     },
    .{ ".tmp"                 , ""                                     },
    .{ ".tpm"                 , ""                                     },
    .{ ".trashes"             , "MacOS trash metadata"                 },
    .{ ".user"                , "User-specific settings"               },
    .{ ".vmsn"                , "VMware snapshot"                      },
    .{ ".vmss"                , "VMware suspend state"                 },
    .{ ".xauthority"          , "X11 authentication"                   },
    .{ ".xsession-errors"     , "X session error log"                  },

    // Downloads
    .{ ".!ut"                 , "uTorrent incomplete"                  },
    .{ ".crdownload"          , "Chrome partial download"              },
    .{ ".download"            , "Safari download"                      },
    .{ ".downloading"         , "Download in progress"                 },
    .{ ".filepart"            , "Partial download file"                },
    .{ ".opdownload"          , "Opera partial download"               },
    .{ ".part"                , "Firefox partial download"             },
    .{ ".partial"             , "Incomplete download"                  },

    // Logs
    .{ ".blf"                 , "Windows registry transaction logs"    },
    .{ ".etl"                 , "Windows event trace logs"             },
    .{ ".jsonl"               , "JSON log"                             },
    .{ ".ldf"                 , "SQL Server log"                       },
    .{ ".log"                 , "Log files"                            },
    .{ ".plg"                 , "Visual Studio build log"              },
    .{ ".regtrans-ms"         , "Windows registry transaction logs"    },
    .{ ".tlog"                , "Build log files"                      },

    // Development files
    .{ ".a"                   , "Static library"                       },
    .{ ".aps"                 , "Visual Studio resource cache"         },
    .{ ".cmi"                 , "OCaml compiled interface"             },
    .{ ".cmo"                 , "OCaml compiled object"                },
    .{ ".cover"               , "Extension for annotated source files" },
    .{ ".coverage"            , "coverage.py raw data"                 },
    .{ ".db-journal"          , "SQLite rollback journal"              },
    .{ ".dylib"               , "Dynamic library"                      },
    .{ ".egg"                 , "Python package created by setuptools" },
    .{ ".elc"                 , "Emacs Lisp compiled"                  },
    .{ ".exp"                 , "Export file"                          },
    .{ ".fasl"                , "Lisp compiled file"                   },
    .{ ".gch"                 , "GCC precompiled headers"              },
    .{ ".hi"                  , "Haskell interface"                    },
    .{ ".idb"                 , "Intermediate database files"          },
    .{ ".ilk"                 , "Incremental link files"               },
    .{ ".lastbuildstate"      , "MSBuild state tracking"               },
    .{ ".lib"                 , "Static library (Windows)"             },
    .{ ".map"                 , "Linker map files"                     },
    .{ ".mdf-journal"         , "SQLite journal"                       },
    .{ ".o"                   , "Object file (ELF/Mach-O)"             },
    .{ ".obj"                 , "Object file (COFF/PE)"                },
    .{ ".opt"                 , "Visual Studio workspace options"      },
    .{ ".pdb"                 , "Program database files"               },
    .{ ".pyc"                 , "Python compiled"                      },
    .{ ".pyd"                 , "Python dynamic module"                },
    .{ ".pyo"                 , "Python optimized"                     },
    .{ ".rbc"                 , "Ruby bytecode"                        },
    .{ ".res"                 , "Compiled resources"                   },
    .{ ".sassc"               , "Sass cache"                           },
    .{ ".scratch"             , "Scratch programming temporary"        },
    .{ ".sqlite-shm"          , "Browser databases"                    },
    .{ ".sqlite-wal"          , "Browser databases"                    },
    .{ ".unsuccessfulbuild"   , ""                                     },

    // Thumbnails files
    .{ ".thumbnails"          , "Thumbnail cache directory"            },
    .{ ".thumbs"              , "Thumbnail cache"                      },

    // Backup files
    .{ ".bak"                 , "Backup files"                         },

    // Lock files
    .{ ".lck"                 , "VMware lock files"                    },
    .{ ".lock"                , ""                                     },
    .{ ".lok"                 , ""                                     },
});

pub const LINE_TERMINATORS = [_][]const u8{
    "\r\n",  // CRLF: Windows, DOS, OS/2, CP/M, Atari TOS, Symbian, HTTP/SMTP/FTP/MIME
    "\n\r",  // LF+CR: Acorn BBC / RISC OS spooled text
    "\n",    // LF: Linux, macOS, BSD, Android, Amiga, BeOS, RISC OS
    "\r",    // CR: classic Mac OS, Commodore, TRS-80, ZX Spectrum, OS-9
};

/// Text files extensions
pub const TEXT_EXTENSIONS = std.StaticStringMap([]const u8).initComptime(.{
    .{ ".adoc"          , "" },
    .{ ".asm"           , "" },
    .{ ".ass"           , "" },
    .{ ".atom"          , "" },
    .{ ".awk"           , "" },
    .{ ".bas"           , "" },
    .{ ".bash"          , "" },
    .{ ".bat"           , "" },
    .{ ".c"             , "" },
    .{ ".cc"            , "" },
    .{ ".cfg"           , "" },
    .{ ".cjs"           , "" },
    .{ ".clj"           , "" },
    .{ ".cmake"         , "" },
    .{ ".cmd"           , "" },
    .{ ".cob"           , "" },
    .{ ".conf"          , "" },
    .{ ".config"        , "" },
    .{ ".cpp"           , "" },
    .{ ".cs"            , "" },
    .{ ".csproj"        , "" },
    .{ ".css"           , "" },
    .{ ".csv"           , "" },
    .{ ".cxx"           , "" },
    .{ ".dart"          , "" },
    .{ ".diff"          , "" },
    .{ ".dockerignore"  , "" },
    .{ ".editorconfig"  , "" },
    .{ ".el"            , "" },
    .{ ".env"           , "" },
    .{ ".erl"           , "" },
    .{ ".ex"            , "" },
    .{ ".exs"           , "" },
    .{ ".f90"           , "" },
    .{ ".fish"          , "" },
    .{ ".fs"            , "" },
    .{ ".gcode"         , "" },
    .{ ".geojson"       , "" },
    .{ ".gitattributes" , "" },
    .{ ".gitignore"     , "" },
    .{ ".go"            , "" },
    .{ ".gpx"           , "" },
    .{ ".gql"           , "" },
    .{ ".gradle"        , "" },
    .{ ".graphql"       , "" },
    .{ ".groovy"        , "" },
    .{ ".h"             , "" },
    .{ ".hpp"           , "" },
    .{ ".hs"            , "" },
    .{ ".htm"           , "" },
    .{ ".html"          , "" },
    .{ ".ics"           , "" },
    .{ ".ini"           , "" },
    .{ ".java"          , "" },
    .{ ".jl"            , "" },
    .{ ".js"            , "" },
    .{ ".json"          , "" },
    .{ ".jsonl"         , "" },
    .{ ".jsx"           , "" },
    .{ ".kml"           , "" },
    .{ ".kt"            , "" },
    .{ ".kts"           , "" },
    .{ ".ldif"          , "" },
    .{ ".less"          , "" },
    .{ ".lisp"          , "" },
    .{ ".lock"          , "" },
    .{ ".log"           , "" },
    .{ ".lrc"           , "" },
    .{ ".lua"           , "" },
    .{ ".m"             , "" },
    .{ ".map"           , "" },
    .{ ".markdown"      , "" },
    .{ ".md"            , "" },
    .{ ".mjs"           , "" },
    .{ ".mk"            , "" },
    .{ ".ml"            , "" },
    .{ ".mm"            , "" },
    .{ ".ndjson"        , "" },
    .{ ".nfo"           , "" },
    .{ ".nim"           , "" },
    .{ ".opml"          , "" },
    .{ ".org"           , "" },
    .{ ".pas"           , "" },
    .{ ".patch"         , "" },
    .{ ".php"           , "" },
    .{ ".pl"            , "" },
    .{ ".plist"         , "" },
    .{ ".pm"            , "" },
    .{ ".po"            , "" },
    .{ ".pot"           , "" },
    .{ ".properties"    , "" },
    .{ ".proto"         , "" },
    .{ ".ps"            , "" },
    .{ ".ps1"           , "" },
    .{ ".psm1"          , "" },
    .{ ".py"            , "" },
    .{ ".pyw"           , "" },
    .{ ".r"             , "" },
    .{ ".rb"            , "" },
    .{ ".reg"           , "" },
    .{ ".resx"          , "" },
    .{ ".rs"            , "" },
    .{ ".rss"           , "" },
    .{ ".rst"           , "" },
    .{ ".rtf"           , "" },
    .{ ".s"             , "" },
    .{ ".sass"          , "" },
    .{ ".scala"         , "" },
    .{ ".scm"           , "" },
    .{ ".scss"          , "" },
    .{ ".sh"            , "" },
    .{ ".sln"           , "" },
    .{ ".sql"           , "" },
    .{ ".srt"           , "" },
    .{ ".ssa"           , "" },
    .{ ".strings"       , "" },
    .{ ".sub"           , "" },
    .{ ".svelte"        , "" },
    .{ ".svg"           , "" },
    .{ ".swift"         , "" },
    .{ ".tcl"           , "" },
    .{ ".tex"           , "" },
    .{ ".text"          , "" },
    .{ ".toml"          , "" },
    .{ ".tsv"           , "" },
    .{ ".tsx"           , "" },
    .{ ".tx"            , "" },
    .{ ".txt"           , "" },
    .{ ".vb"            , "" },
    .{ ".vbs"           , "" },
    .{ ".vcf"           , "" },
    .{ ".vcxproj"       , "" },
    .{ ".vtt"           , "" },
    .{ ".vue"           , "" },
    .{ ".wsdl"          , "" },
    .{ ".xhtml"         , "" },
    .{ ".xml"           , "" },
    .{ ".xsd"           , "" },
    .{ ".xsl"           , "" },
    .{ ".xslt"          , "" },
    .{ ".yaml"          , "" },
    .{ ".yml"           , "" },
    .{ ".zig"           , "" },
    .{ ".zsh"           , "" },
});

/// Forbidden filenames of windows system
pub const WINDOWS_RESTRICTIONS = std.StaticStringMap([]const u8).initComptime(.{
    .{ "CON"  , "" }, .{ "PRN"  , "" }, .{ "AUX"  , "" }, .{ "NUL"  , "" },
    .{ "COM1" , "" }, .{ "COM2" , "" }, .{ "COM3" , "" }, .{ "COM4" , "" }, .{ "COM5" , "" }, .{ "COM6" , "" },
    .{ "COM7" , "" }, .{ "COM8" , "" }, .{ "COM9" , "" },
    .{ "LPT1" , "" }, .{ "LPT2" , "" }, .{ "LPT3" , "" }, .{ "LPT4" , "" }, .{ "LPT5" , "" }, .{ "LPT6" , "" },
    .{ "LPT7" , "" }, .{ "LPT8" , "" }, .{ "LPT9" , "" },
});
