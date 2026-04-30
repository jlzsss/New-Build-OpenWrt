
function PREPARECHEADER(script, syntaxcheck)  
  --parse the structures
  
  local definedStructures={} --list of structure objects from dissectStructurePath

  for i=0,script.Count-1 do    
    local l=script[i]:trim()
    
    if l:upper()=='USEMONO()' then --PREPARECHEADER runs before USEMONO is handled
      LaunchMonoDataCollector() 
    end
    
    if l:upper():startsWith('PREPARECHEADER(') then   
      
      if l:endsWith(')')==false then error('PREPARECHEADER syntax error') end      
      local paramsstr=l:sub(16,-2)
      local params={}
      for x in paramsstr:gmatch("[^,]+") do
        table.insert(params, x)
      end  
      
      if #params==0 then
        error('Error in '..l..': Not enough parameters');
      end
      --param1 is the base structure type. First check if it is already defined in definedStructures
      local structname=params[1]
      table.remove(params,1) --the rest is fieldnames
      
      local currentStructure=nil
      for j=1,#definedStructures do
        if definedStructures[i].Name:upper()==structname:upper() then
          currentStructure=definedStructures[i]
          break;
        end
      end
      
      if currentStructure==nil then
       -- printf("dissecting %s", structname)
        currentStructure,err=dissectStructurePath(structname, params) 
        
        if (currentStructure==nil) then
          _G.lastparams=params
          error('Failure dissecting '..structname..' ('..err..')')
        end
        table.insert(definedStructures,currentStructure)
      else
        --printf("appending to %s",currentStructure.Name)
        currentStructure=dissectStructurePath(currentStructure, params)
      end
      
      script[i]='' --remove the line
    end
  end
  
  if #definedStructures>0 then
  
    --convert the definedStructures to C headers. By grouping them, overlapping types will be disgarded from the header file
    local header=generate_c_header(definedStructures)
  
    script.insertText(0,string.format([[
{$c}
//header created by PREPARECHEADER lines 
%s


{$asm}
]],header))

    --showMessage(script.text)  
  end
  
end

registerAutoAssemblerCommand("PREPARECHEADER", function() end)  --highlight but don't do anything else
registerAutoAssemblerPrologue(PREPARECHEADER)
    