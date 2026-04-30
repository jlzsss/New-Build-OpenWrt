stringstruct=createStructure('string')
local e=stringstruct.addElement()
e.vartype=vtString
e.ByteSize=100

stringstruct.Internal=true


widestringstruct=createStructure('widestring')
local e=widestringstruct.addElement()
e.vartype=vtUnicodeString
e.ByteSize=200

widestringstruct.Internal=true

