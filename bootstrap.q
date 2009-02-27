.u.LOADED:()
.u.FILELOADING:`
.u.PKGLOADING:""
.u.require:{
 p: $[-11h ~ type x;x;
  / I'd like the require paths to be the same across platforms
  [file: `$ 1 _ string ` sv `$@["/" vs x;0;":",];
   paths: ` sv' .u.QPATH,'file;
   / We'll go with the first one that we find
   path: first paths where not 0 = (count key@) each paths;
   if[null path;
    '"File not found in library load paths:\n\t", "\n\t" sv 1 _' string paths];
   / The convention used for packages will to be start by using an init file
   $[-11h ~ type key path;path;` sv path,`init.q]]];
 if[0 = count key p;'"File not found: ",string 1 _ p];
 / Let the name of the file being loaded and the "package" if available be accessed
 oldFileLoading: .u.FILELOADING;
 oldPkgLoading: .u.PKGLOADING;
 .u.PKGLOADING: $[(-11h ~ type x) or x like "*.q";.u.PKGLOADING;x];
 .u.FILELOADING: p;
 if[not p in .u.LOADED;
  system "l ", 1 _ string p;
  .u.LOADED,:p];
 .u.FILELOADING: oldFileLoading;
 .u.PKGLOADING: oldPkgLoading;
 }
