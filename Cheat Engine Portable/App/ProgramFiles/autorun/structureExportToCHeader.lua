require('forEachForm')

-- Lua script for Cheat Engine: Generate C header from a list of Structure objects,
-- handling forward declarations, gaps, overlaps, recursion, nested structs, all value types,
-- signed/unsigned integer display, unnamed fields, and cleans up invalid C identifier characters in element names.
-- Assumes vtByte .. vtWideString are already defined in CE. (Do not redeclare them!)

local function mapVartypeToC(elem, child_struct_typename)
  local vt = elem.Vartype
  local display = elem.DisplayMethod
  local signed = (display == 'dtSignedInteger')
  if vt == vtByte then
    return signed and "signed char" or "unsigned char", elem.Bytesize
  elseif vt == vtWord then
    return signed and "short" or "unsigned short", elem.Bytesize
  elseif vt == vtDword then
    return signed and "int" or "unsigned int", elem.Bytesize
  elseif vt == vtQword then
    return signed and "long long" or "unsigned long long", elem.Bytesize
  elseif vt == vtSingle then
    return "float", elem.Bytesize
  elseif vt == vtDouble then
    return "double", elem.Bytesize
  elseif vt == vtPointer then
    if child_struct_typename then
      if elem.NestedStructure then
        return child_struct_typename, elem.Bytesize
      else
        return child_struct_typename .. "*", elem.Bytesize
      end
    else
      return "void*", elem.Bytesize
    end
  elseif vt == vtString then
    return "char", elem.Bytesize
  elseif vt == vtWideString then
    return "wchar_t", elem.Bytesize // 2
  else
    return "int", elem.Bytesize
  end
end

local function getStructTypeName(structure)
  -- Only allow valid C identifier characters for struct names
  return tostring(structure.Name):gsub("[^%w_]", "_")
end

local function getElementName(elem)
  local rawname = elem.Name or ""
  local name
  if rawname == "" then
    name = string.format("unnamed%X", elem.Offset or 0)
  else
    -- Replace invalid C identifier characters with '_'
    name = tostring(rawname):gsub("[^%w_]", "_")
    -- C identifiers can't start with a digit
    if name:match("^[0-9]") then
      name = "_" .. name
    end
  end
  return name
end

-- Internal: generate a single struct definition, with recursion
local function generate_single_struct_header(structure, defined_structs, all_struct_names, struct_order)
  local struct_name = getStructTypeName(structure)
  if defined_structs[struct_name] then
    return "" -- already defined, skip
  end
  defined_structs[struct_name] = true
  all_struct_names[struct_name] = true
  table.insert(struct_order, struct_name)

  local guard = ("_%s_H_"):format(struct_name):upper():gsub("%W","_")
  local out = {}
  table.insert(out, "#ifndef "..guard)
  table.insert(out, "#define "..guard)
  table.insert(out, "")
  table.insert(out, "#include <stdint.h>")
 -- table.insert(out, "#include <wchar.h>") --add a bunch of code
  table.insert(out, "")

  table.insert(out, ("typedef struct %s {"):format(struct_name))

  local used_bytes = {}
  local current_offset = 0
  local reserved_count = 0
  local child_struct_defs = {}

  for i=0, structure.Count-1 do
    local elem = structure.Element[i]
    if elem then
      local elem_offset = elem.Offset
      local elem_end = elem_offset + elem.Bytesize
      local child_struct_typename = nil
      local name = getElementName(elem)
      if elem.Vartype == vtPointer and elem.ChildStruct then
        child_struct_typename = getStructTypeName(elem.ChildStruct)
        if not defined_structs[child_struct_typename] then
          table.insert(child_struct_defs, generate_single_struct_header(elem.ChildStruct, defined_structs, all_struct_names, struct_order))
        end
        all_struct_names[child_struct_typename] = true
      end

      local ctype, size = mapVartypeToC(elem, child_struct_typename)
      local overlap = false
      for b = elem_offset, elem_end - 1 do
        if used_bytes[b] then
          overlap = true
          break
        end
      end
      if overlap then
        table.insert(out, ("    // Field '%s' REMOVED due to overlap with a previous field"):format(name))
      else
        if elem_offset > current_offset then
          local gap = elem_offset - current_offset
          reserved_count = reserved_count + 1
          table.insert(out, ("    unsigned char reserved_%d[%d]; // gap"):format(reserved_count, gap))
          current_offset = current_offset + gap
        end
        if elem.Vartype == vtString or elem.Vartype == vtWideString then
          table.insert(out, ("    %s %s[%d];"):format(ctype, name, size))
          if elem.Vartype == vtWideString then
            current_offset = current_offset + size * 2
          else
            current_offset = current_offset + size
          end
        elseif elem.Vartype == vtPointer and elem.ChildStruct and elem.NestedStructure then
          table.insert(out, ("    %s %s;"):format(ctype, name))
          current_offset = current_offset + elem.Bytesize
        else
          local use_array = false
          local type_size = size
          if elem.Vartype == vtByte then type_size = 1
          elseif elem.Vartype == vtWord then type_size = 2
          elseif elem.Vartype == vtDword then type_size = 4
          elseif elem.Vartype == vtQword then type_size = 8
          elseif elem.Vartype == vtSingle then type_size = 4
          elseif elem.Vartype == vtDouble then type_size = 8
          elseif elem.Vartype == vtPointer then type_size = elem.Bytesize
          end
          if elem.Bytesize > type_size then
            use_array = true
          end
          if use_array then
            table.insert(out, ("    %s %s[%d];"):format(ctype, name, elem.Bytesize // type_size))
          else
            table.insert(out, ("    %s %s;"):format(ctype, name))
          end
          current_offset = current_offset + elem.Bytesize
        end
        for b = elem_offset, elem_end - 1 do
          used_bytes[b] = true
        end
      end
    end
  end

  table.insert(out, ("} %s;"):format(struct_name))
  table.insert(out, "")
  table.insert(out, "#endif // "..guard)
  if #child_struct_defs > 0 then
    table.insert(out, table.concat(child_struct_defs, "\n"))
  end
  return table.concat(out, "\n")
end

-- Main: Accepts a list of structures, returns a header for all of them and their dependencies,
-- and emits forward declarations.
function generate_c_header(struct_list)
  if type(struct_list) ~= "table" then
    struct_list={struct_list}    
  end
  local defined_structs = {}
  local headers = {}
  local all_struct_names = {}
  local struct_order = {}

  for _, structure in ipairs(struct_list) do
    local h = generate_single_struct_header(structure, defined_structs, all_struct_names, struct_order)
    if h ~= "" then
      table.insert(headers, h)
    end
  end

  -- Forward declarations for all struct names
  local fwd = {}
  for struct_name, _ in pairs(all_struct_names) do
    table.insert(fwd, string.format("typedef struct %s %s;", struct_name, struct_name))
  end
  table.sort(fwd) -- sort alphabetically for predictability

  return table.concat(fwd, "\n").."\n\n"..table.concat(headers, "\n\n")
end


function dissectStructurePath(basestructurename, ...)
  --returns a structure where the path to field1, field2, field3... are followed
  --alternatives:
  --basestructurename can also be a defined structures

  --the fieldnames can be entered inside a table as well
  local definedStructures={}
  

  local structure
  local createdStructure=false
  local basetype=type(basestructurename)
  if basetype=='string' then
    --define the main structure
    structure=createStructureFromName(basestructurename)
    createdStructure=true --remember to destroy this in case the path fails
  elseif basetype=='userdata' then
    structure=basestructurename
  end
  
  if structure then
    local fieldnames={}
    local args={...}

    if #args>=1 then
      if type(args[1])=='table' then
        fieldnames=args[1]
      elseif type(args[1])=='string' then
        for i=1,#args do
          fieldnames[i]=args[i]
        end       
      end
    end

    local currentstructure=structure
    for i=1,#fieldnames do
      if fieldnames[i]==nil or type(fieldnames[i])~='string' then return nil,'fieldname '..i..' is not valid' end
      local foundfield=false
      for j=0,currentstructure.Count-1 do
        if currentstructure[j].Name==fieldnames[i]:trim() then
          foundfield=true
          if (currentstructure[j].ChildClassName==nil) then
             return nil,'Field '..i..':'..fieldnames[i]..' has no childclassname set'
          end


          if currentstructure[j].ChildStruct==nil then
            currentstructure[j].ChildStruct=createStructureFromName(currentstructure[j].ChildClassName)
            if currentstructure[j].ChildStruct==nil then
              if createdStructure then 
                structure.destroy()
              end
              return nil,'Failure creating structure for '..currentstructure[i].ChildClassName
            end
            currentstructure=currentstructure[j].ChildStruct
            break
          end
        end
      end

      if not foundfield then return nil,'field '..fieldnames[i]..' not found' end
    end
  end

  return structure 
end


forEachAndFutureForm('TfrmStructures2',function(f)
  local menu=f.Menu
  local lastUsedFolder=nil
  
  if f.miExportToCHeader==nil then
    local mi=createMenuItem(f)
    mi.Caption='Export to C header file'
    mi.OnClick=function(sender)
      if f.MainStruct then
        local h=generate_c_header(f.MainStruct)
        if h then
          local dlg = createSaveDialog()
          dlg.DefaultExt = 'h'
          dlg.Filter = translate('Header files (*.h)|*.h')
          dlg.Options = '[ofOverwritePrompt]'

          -- restore last used folder if available
          if lastUsedFolder ~= nil then
            dlg.InitialDir = lastUsedFolder
          end

          -- set default filename from structure name
          if f ~= nil and f.MainStruct ~= nil then
            dlg.FileName = f.MainStruct.Name .. '.h'
          end

          if dlg.execute() then
            local filepath = dlg.FileName
            local fhandle = io.open(filepath, 'w')
            if fhandle then
              fhandle:write(h)
              fhandle:close()
              beep() -- success signal

              lastUsedFolder = extractFilePath(filepath)
              --shellExecute('notepad "'..filepath..'"')
            else
              messageDialog('Error: Could not open file for writing.', mtError)
            end
          end 
        end    
      end
    end
    
    mi.name='miExportToCHeader'
    
    f.File1.insert(f.miExportAll.MenuIndex+1,mi)
  else
   -- print("miExportToCHeader already existed")
  end
end)