function ShowAddressListWindow() --window made with copilot on github
  local dpiscale = getScreenDPI() / 96
  local entries

  local form = createForm(false)
  form.Caption = "Address List (Please Wait)"
  form.Width = 400 * dpiscale
  form.Height = 300 * dpiscale
  form.BorderStyle = "bsSizeable"
  form.Position = "poScreenCenter"

  local lv = createListView(form)
  lv.Align = alClient
  lv.ViewStyle = 'vsReport'
  lv.ReadOnly = true
  lv.RowSelect = true
  lv.HideSelection = false
  lv.MultiSelect = true
  lv.OwnerData = true -- Enable virtual/owner data mode

  lv.Columns.add().Caption = "Name"
  lv.Columns[0].Width = 200 * dpiscale
  lv.Columns.add().Caption = "Address"
  lv.Columns[1].Width = 180 * dpiscale



  -- Provide item data on demand (owner data)
  lv.OnData = function(sender, item)
    local idx = item.Index + 1 -- Lua uses 1-based indexing
    local entry = entries[idx]
    if entry then
      item.Caption = entry.name
      item.SubItems.clear()
      item.SubItems.add(string.format('%X', entry.address))
      item.Data = entry.address
    else
      item.Caption = ""
      item.SubItems.clear()
      item.Data = nil
    end
  end

  -- On double-click, set Hexadecimal view address
  lv.OnDblClick = function(sender)
    local sel = sender.Selected
    if sel then
      local address = sel.Data
      if address then
        local mv = getMemoryViewForm()
        mv.Show()
        mv.HexadecimalView.Address = address
      end
    end
  end

  -- Use createFindDialog for searching names
  local function showFindDialog()
    local fd = createFindDialog(form)
    fd.Options = '[frDown]'
    fd.Title = 'Find name'
    fd.OnFind = function(sender)
      local search = sender.FindText:lower()
      for i = 1, #entries do
        if entries[i].name:lower():find(search, 1, true) then
          lv.ItemIndex = i - 1
          lv.TopItem = i - 1
          lv.Selected = lv.Items[i - 1]
          break
        end
      end
    end
    fd.Execute()
  end

  -- Context menu setup
  local cm = createPopupMenu(form)

  -- "Find" menu item
  local miFind = createMenuItem(cm)
  miFind.Caption = "Find"
  miFind.Shortcut = "Ctrl+F"
  miFind.OnClick = showFindDialog
  cm.Items.add(miFind)

  -- "Copy name" menu item
  local miCopyName = createMenuItem(cm)
  miCopyName.Caption = "Copy name"
  miCopyName.Shortcut = "Ctrl+C"
  miCopyName.OnClick = function()
    local sel = lv.Selected
    if sel then
      writeToClipboard(sel.Caption)
    end
  end
  cm.Items.add(miCopyName)
  
  local miSaveToFile = createMenuItem(cm)
  miSaveToFile.Caption = "Save to text file..."
  miSaveToFile.OnClick = function()
    local sd = createSaveDialog(form)
    sd.Filter = "Text files (*.txt)|*.txt"
    sd.DefaultExt = "txt"
    sd.Options = "[ofOverwritePrompt]"
    if sd.Execute() then
      local f = assert(io.open(sd.FileName, "w"))
      for i = 1, #entries do
        local e = entries[i]
        f:write(string.format("%s\t%08X\n", e.name, e.address))
      end
      f:close()
      shellExecute(sd.FileName)
    end
  end
  cm.Items.add(miSaveToFile)
  

  lv.PopupMenu = cm
  lv.Enabled=false
  lv.Cursor=crHandPoint

  form.Show()
  
  function updateEntries(newentries)
    if newentries then
      entries=newentries
      lv.Items.Count = #entries -- Tell the listview how many entries to expect    
    end
    
    lv.Enabled=true
    lv.Cursor=crDefault   

    form.Caption = "Address List"    
    
    form.bringToFront()
    beep()
  end

  
  return form, updateEntries
end
  

function spawnEnumStaticsWindow(DataSource, frmDotNetInfo)
  --spawn a thread that obtain a list of static addresses
  local form, updateEntries=ShowAddressListWindow()
  
  if DataSource.ParsedStatics==nil then
    
    monolog('parse statics started')
    local oldcaption=frmDotNetInfo.miEnumAllStatics.Caption
    local frmDotNetInfoList=getDotNetInfoList()
    for i=1,#frmDotNetInfoList do
      frmDotNetInfoList[i].miEnumAllStatics.Enabled=false
      frmDotNetInfoList[i].miEnumAllStatics.Caption=oldcaption..translate(' (Processing... Please wait!)')
    end
    
    DataSource.debug={}
    
    if DataSource.ParsingStatics==nil then
      DataSource.ParsingStatics=createThread(function(t)
        --parse the statics
        local r,r2=pcall(function()
          local results={}
          for i=1,#DataSource.Domains do
            DataSource.debug.i=i
            
            if DataSource.Domains[i].Images==nil then
              DataSource.getImages(DataSource.Domains[i])
            end
          
            if DataSource.Domains[i].Images==nil then return end
            
            for j=1,#DataSource.Domains[i].Images do
              local HasToFetchClasses=false
              DataSource.debug.j=j
              
              synchronize(function() --got to check this quickly in the main thread
                --print("mainthread. Checking if Classes is nil")
                if t.Terminated then return end 
                if DataSource.Domains[i].Images[j].Classes==nil then
                  HasToFetchClasses=true
                  DataSource.Domains[i].Images[j].Classes={}
                  DataSource.Domains[i].Images[j].Classes.Busy=true                      
                end
              end)
              
              if HasToFetchClasses then                    
                --print('Getting classes')                  
                DataSource.getClasses(DataSource.Domains[i].Images[j])
                DataSource.Domains[i].Images[j].Classes.Busy=false                      
              end
              
              for k=1,#DataSource.Domains[i].Images[j].Classes do  
                DataSource.debug.k=k
                if t.Terminated then break end
                
                --get all the statics of each class
                if DataSource.Domains[i].Images[j].Classes[k].Fields==nil then                  
                  DataSource.getClassFields(DataSource.Domains[i].Images[j].Classes[k])
                end                
                  
                if DataSource.Domains[i].Images[j].Classes[k].Fields then
                  for l=1,#DataSource.Domains[i].Images[j].Classes[k].Fields do
                    DataSource.debug.l=l
                    if t.Terminated then break end
                    
                    local e=DataSource.Domains[i].Images[j].Classes[k].Fields[l]
                    if e.Static and e.Address then
                      local e2={}
                      e2.name=DataSource.Domains[i].Images[j].Classes[k].Name..'.'..e.Name
                      e2.address=e.Address
                      
                      table.insert(results,e2) 
                    end
                    DataSource.debug.l=nil
                  end                  
                end
                DataSource.debug.k=nil
              end 
              DataSource.debug.j=nil
            end
            DataSource.debug.i=nil
          end  

          DataSource.ParsedStatics=results
        end)    

        if not r then
          print('Parse static error:'..r2)
          --monolog('parse statics error:'..r2)
        end
        
        monolog('parse statics finished')      
        synchronize(function()                      
          local frmDotNetInfoList=getDotNetInfoList()
          for i=1,#frmDotNetInfoList do
            frmDotNetInfoList[i].miEnumAllStatics.Enabled=true
            frmDotNetInfoList[i].miEnumAllStatics.Caption=oldcaption
          end

          if DataSource.ParsedStatics then  
            updateEntries(DataSource.ParsedStatics)
          else
            updateEntries(nil)
          end
          
          if not t.Terminated then
            DataSource.ParsingStatics=nil
          end
        end)        
      end)
      
      form.OnClose=function()
        if DataSource.ParsingStatics then --this can be safely done as DataSource.ParsingStatics=nil only gets done inside the main thread
          DataSource.ParsingStatics.Terminate() --just tell it to shut the fuck up when it feels like it
          DataSource.ParsingStatics=nil
        end       
        
        return caFree
      end
    end --else it was still going on (but shouldn't be possible to reach here as the menuitem is disabled)
  else
    --show dialog  
    local form, updateEntries=ShowAddressListWindow()
    updateEntries(DataSource.ParsedStatics)
  end 


end

