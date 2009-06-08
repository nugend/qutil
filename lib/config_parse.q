\d .utl
configParsing:((),`)!enlist (::)

configParsing.stripComments:{[l];l where not any l like/: (";*";"#*")}

configParsing.sections:{[fn;l];
  cl:count l;
  p:where (rtrim each l) like "[[]*]"; / Left square brackets can't simply be escaped
  if[not count fn;'"There were no sections found in the file: '",fn,"'"];
  sectionNames:(1 _ -1 _ rtrim @) each l p;
  sectionNames!l (p cut til count l) except\: p / Cut in such a way as to return only the lines in each section
  }
  
configParsing.pairs:{[fn;l];
  n:where any l like\:/: ("*:*";"*=*");
  if[not 0 in n;'"There was an improperly formatted line in the file: '",fn,"'"];
  badLines: where not (l (til count l) except n) like "[ \t]*";
  if[count badLines;'"There was an improperly formatted line in the file: '",fn,"'";];
  l:raze each n cut l;
  nPos: {min raze x ss/: "=:"} each l;
  d:flip (0,'nPos) cut' l;
  d[0]: trim each d[0];
  d[1]: (trim 1 _) each d[1];
  d:(!) . d;
  if[any "" ~/: key d;'"There was an empty key in the file: '",fn,"'";];
  d
  }

configParsing.multiValue:{[b;d];
  $[b;
    [p:{where x ~\: y}[key d] each dk:distinct key d; / Treat multivalued params by joining the results
      dk!value[d] @/: @[p;where 1 = count each p;first]]; / If only one index is being used, it shouldn't be enlisted
    dk!d dk:distinct key d
    ]
  }

configParsing.substituteLine:{[d;l];
  pred:(p[0] < p[1]) and 2 = count p: first flip l ss/: ("%(";")s");
  if[() ~ pred;:l]; / If there are no substitutions, p is an empty list and the normal predicate doesn't work right
  $[pred;
    [pieces:(0,p) cut l;
      if[not (2 _ pieces) in key d;:l];                       / Abort early if there are missing substitutions
      .z.s[d;pieces[0],sv[" ";d 2 _ pieces 1],2 _ pieces 2]]; / sv because the value might be a list
    l
    ]
  }

multiValuedConfigs:0b

parseConfig:{[file];
  l:$[-11h ~ type file;[fn:file;read0 file];[fn:"input string";file]];
  l:configParsing.stripComments l;
  cfg:configParsing.pairs[fn] each configParsing.sections[fn] l;
  {[default;d];
   d:default,configParsing.multiValue[multiValuedConfigs;d];
   configParsing.substituteLine[d] each d}[cfg["DEFAULT"]] each cfg
  }
