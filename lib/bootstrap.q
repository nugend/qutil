.utl.LOADED:()
.utl.FILELOADING:`
.utl.PKGLOADING:""

.utl.baseLoadV:{[x;v;allowReload];
 pkgInfo: $[-11h ~ type x;
  `file`package!(x;x);
  / If a generic list is passed, we treat it as a symbol and characters, using the symbol as a package name
  / This is useful to allow requires that reference relative paths
  0h ~ type x;
  `file`package!(` sv x[0], `$"/" vs 1 _ x;x[0]);
  .utl.requireVH.findV[x;v]];
 / The convention used for packages will be to start by using an init file
 file: $[-11h ~ type key pkgInfo[`file];pkgInfo[`file];` sv pkgInfo[`file],`init.q];
 if[not count key file; '"File '",(1 _ string file),"' not found"];
 oldFileLoading: .utl.FILELOADING;
 oldPkgLoading: .utl.PKGLOADING;
 / Let the name of the file being loaded and the "package" if available be accessed
 `.utl.PKGLOADING set $[pkgInfo[`file] like "*.q";.utl.PKGLOADING;pkgInfo[`package]];
 `.utl.FILELOADING set .utl.realPath file;
 result:1b;
 / The require function prevents files from being loaded that have already been loaded
 / TODO:It is not smart enough to ignore a differently versioned module yet
 if[allowReload or not file in .utl.LOADED;
  / NOTE:Consider supporting a debug flag to allow errors on require go uncaught
  result:@[{system "l ", x;1b};1 _ string file;(::)];  / The file is loaded and errors are caught
  if[1b ~ result;.[`.utl.LOADED;();union;file]];
  ];
 `.utl.FILELOADING set oldFileLoading;
 `.utl.PKGLOADING set oldPkgLoading;
 $[1b ~ result;1b;'"Error loading '",(1 _ string file),"': ",result];
 }

.utl.loadV:.utl.baseLoadV[;;1b]
.utl.load:.utl.baseLoadV[;"";1b]
.utl.requireV:.utl.baseLoadV[;;0b]
.utl.require:.utl.baseLoadV[;"";0b]

/Get the real path of a filehandle cross platform (hopefully)
.utl.realPath:{
 rPath:{[absm;p] $[p like absm;p;` sv (hsym `$system "cd"), (`$1 _ string p)]};
 $["w" ~ (string .z.o) 0;
  rPath[":[A-z]:*";x];
  rPath[":/*";x]
  ]
 }

.utl.requireVH:((),`)!(),(::)
.utl.requireVH.findV:{[x;v];
 / The paths passed to require should be the same across platforms
 packageName: first pathComponents: "/" vs x;
 allPackages: raze {(` sv x,) each key x} each .utl.QPATH;
 matchingPackages: allPackages where allPackages like "*",packageName,"*";
 matchingPackages: matchingPackages where .utl.requireVH.makeFilter[v]  each matchingPackages;
 / Use the highest available package meeting the requirements
 matchingPackage: first matchingPackages idesc .utl.requireVH.numVNStr .utl.requireVH.VNStrPath each matchingPackages;
 exactPackage: first allPackages where allPackages like "*",packageName;
 / If a Version String has been provided (not "") we want to use the most recent matching
 / package and *then* fall back to an exact package name match.
 path: $[(v ~ "") and not null exactPackage;exactPackage;
  not null matchingPackage;matchingPackage;
  not null exactPackage;exactPackage;
  '"A matching package was not found for '",x,"' with version string '",v,"'.  Paths searched:\n\t", "\n\t" sv string .utl.QPATH];
 / Package numbers are only considered at the top level, special logic to support
 / sub-package elements (packages and files within a versioned package) is needed
 subPackagePath: $[1 < count pathComponents;`$ 1 _ string ` sv `$@[1 _ pathComponents;0;":",];()];
 file: ` sv path,subPackagePath;
 package: 1 _ string ` sv (hsym last ` vs path),subPackagePath;
 `file`package!(file;package)
 }

/ Compare two Version Number Strings given an operator
/ It's much easier to do the partial application of the arguments for our purposes
/ if the second arg (the one on the right hand side) is passed in first
.utl.requireVH.cmpVNStr:{[op;vsn2;vsn1];
 if[not count vsn1;:0b];
 if[not count vsn2;:1b];
 op . .utl.requireVH.numVNStr (vsn1;vsn2)
 }

/ Create ordinal numbers from a list of Version Number Strings (Because a Version Number String could ostensibly have infinite depth, we need to work on them in groupings)
.utl.requireVH.numVNStr:{[vns];
 if[not count vns;:0];
 vns:"I"$"." vs' (),/:vns;
 s: max count each vns;
 ns:{@[x#0;til count y;:;y]}[s] each vns;   / Fill out each list with 0's
 sum each ns *\: reverse `int$10 xexp' til s / Get the total version numbers
 }

/ Get a Version Number String from the last element of a path
.utl.requireVH.VNStrPath:{"." sv string 1 _ ` vs last ` vs x}

/ Create a pair of operator and Version Number String
.utl.requireVH.parseVStr:{
 v: trim each "," vs x;
 pairs: {(0,0^1 + last x ss "[<>=]") _ x} each v; / Split the version specifiers into operator and number.
 .[pairs;(::;0);:;(("";(),"=";(),"<";(),">";">=";"<=";"<>")!(=;=;<;>;>=;<=;<>)) pairs[;0]] / Create the comparators
 }

/ Creates a Filter function based on a Version String
/ Individual comparison functions are created from each of the comma separated version string elements
.utl.requireVH.makeFilter:{[vstr];
 if[vstr ~ "";:{1b}];
 {all x @\: .utl.requireVH.VNStrPath y}[.utl.requireVH.cmpVNStr ./: .utl.requireVH.parseVStr vstr] / Partially apply the version string elements to get a list of comparators
 }
