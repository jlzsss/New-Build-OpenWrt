--dotnetsearch
if getTranslationFolder()~='' then
  loadPOFile(getTranslationFolder()..'dotnetsearch.po')
end

function spawnDotNetSearchDialog(DataSource, frmDotNetInfo, searchtype)

  local currentScan --rule: only writable in mainthread
  local searchresults={}
  
  
  --spawns a searchdialog. searchtype has 3 options: 0-ClassName, 1-FieldName, 2-MethodName
  local frmSearch=createFormFromFile(getAutorunPath()..'forms'..pathsep..'DotNetSearch.frm')  
  
  frmSearch.cbLimitToClass.OnChange=function(sender)
    if sender.Checked then
      frmSearch.cbLimitToImage.Checked=false
    end
  end
  
  frmSearch.cbLimitToImage.OnChange=function(sender)
    if sender.Checked then
      frmSearch.cbLimitToClass.Checked=false
    end
  end  
  
  
  _G.frmSearch=frmSearch --for debugging
  frmSearch.cbLimitToImage.Enabled=frmDotNetInfo.lbImages.ItemIndex>=0          
  frmSearch.cbLimitToClass.Enabled=frmDotNetInfo.lvClasses.ItemIndex>=0 
  frmSearch.cbScanForFieldTypeNames.visible=searchtype==1
  frmSearch.cbScanForMethodParametersAndTypes.visible=searchtype==2  
    
  if searchtype==0 then --class scan
    frmSearch.Caption=translate('Find Class')    
    frmSearch.cbLimitToClass.Visible=false
    frmSearch.lvResults.Columns.delete(2)
  elseif searchtype==1 then --field scan
    frmSearch.Caption=translate('Find Field')    
    frmSearch.lvResults.Columns[2].Caption='Field'
  elseif searchtype==2 then
    frmSearch.Caption=translate('Find Method')  
    frmSearch.lvResults.Columns[2].Caption='Method'    
  else 
    return nil,'no'
  end
  
  frmSearch.OnClose=function(ca)
    if currentScan then
      currentScan.terminate()    
    end
    frmSearch=nil
    return caFree
  end
  
  frmSearch.lvResults.OnDblClick=function()
    --select the domain, image, class (wait...)
    --then select the field or method if searchtype>0  
    
    local i
    local index=frmSearch.lvResults.ItemIndex
    if index==-1 then
      return --nothing selected
    end
    
    index=index+1
    if index<=#searchresults then
      local r=searchresults[index]
      if r then
        --print(string.format('Domain %d Image %d Class %d', r.DomainIndex, r.ImageIndex, r.ClassIndex))
        frmDotNetInfo.edtClassFilter.Text='' --remove the filter
        
        frmDotNetInfo.lbDomains.ItemIndex=r.DomainIndex-1        
        frmDotNetInfo.lbImages.ItemIndex=r.ImageIndex-1
        
        local timeout=getTickCount()
        while frmDotNetInfo.lvClasses.Items.Count<r.ClassIndex do
          CheckSynchronize(100)
          
          if getTickCount()>timeout+10000 then return end --failure getting the classlist
        end
        
        frmDotNetInfo.lvClasses.ItemIndex=r.ClassIndex-1
        frmDotNetInfo.lvClasses.Items[frmDotNetInfo.lvClasses.ItemIndex].makeVisible(false)
  
      
        if searchtype==1 then
          --r is a field
          frmDotNetInfo.lvFields.Index=r.FieldIndex-1
        elseif searchtype==2 then
          --r is a method
          frmDotNetInfo.lvMethods.ItemIndex=r.MethodIndex-1
          frmDotNetInfo.lvMethods.Items[frmDotNetInfo.lvMethods.ItemIndex].makeVisible(false)
            
        end      

      end
    end
  
  end
  
  
  frmSearch.show()   --not modal (scans can take long)
  

  local oldOnClose=frmDotNetInfo.OnClose
  frmDotNetInfo.OnClose=function(closeAction)
    if currentScan then
      currentScan.terminate()
    end
    
    if oldOnClose then
      return oldOnClose(closeAction)
    else
      return closeAction
    end
  end
  
  frmSearch.btnScan.OnClick=function()
    if currentScan then
      --print("Canceling scan")
      --cancel the current scan
      currentScan.terminate() --this will cause it to kill itself
      currentScan=nil
      frmSearch.btnScan.Caption='   '..translate('Search')..'   '
    else
      
      local searchInput=frmSearch.edtSearchInput.Text
      local imageScanOnly=frmSearch.cbLimitToImage.checked
      local classScanOnly=frmSearch.cbLimitToClass.checked
      local caseSensitive=frmSearch.cbCaseSensitive.checked
      local ImageListIndex=frmDotNetInfo.lbImages.ItemIndex
      local ClassListIndex=frmDotNetInfo.lvClasses.ItemIndex
      local fieldTypeScan=false
      local parameterTypeScan=false
      if searchtype==1 then --type
        fieldTypeScan=frmSearch.cbScanForFieldTypeNames.checked       
      elseif searchtype==2 then
        parameterTypeScan=frmSearch.cbScanForMethodParametersAndTypes.checked              
      end
      
      
      
     
      if not caseSensitive then
        searchInput=searchInput:upper()
      end
      
      
      
      
      if searchInput~='' then    
        frmSearch.btnScan.Caption=translate('Stop')  
        frmSearch.lvResults.Items.clear()
        
        --create the scanthread
        currentScan=createThread(function(t) --these threads are created with freeOnTerminate set to false
          --print("search thread.  Type="..searchtype)
          if t.Terminated then return end
          
          local i,j,k,l
          local currentDomainIndex=1
          local currentImageIndex=1
          local currentClassIndex=1
          local currentFieldIndex=1
          local currentMethodIndex=1
          local filteredList=nil
          
          if imageScanOnly then 
            currentImageIndex=ImageListIndex+1 -- -1 becomes 0
          end
          
          if classScanOnly then
            currentImageIndex=ImageListIndex+1
            currentClassIndex=ClassListIndex+1
            filteredList=frmDotNetInfo.FilteredClassList           
            
          end
          
          
          
          if DataSource.Domains==nil then --would be weird
            DataSource.getDomains() 
          end          
          
          if t.Terminated then return end

          for i=currentDomainIndex,#DataSource.Domains do
            --print("Checking domain "..i)
            if DataSource.Domains[i].Images==nil then
              DataSource.getImages(DataSource.Domains[i])
            end
            
            if DataSource.Domains[i].Images==nil then return end
            
            for j=currentImageIndex,#DataSource.Domains[i].Images do
              --print(string.format("Checking domain %d image %d", i,j))                
              local HasToFetchClasses=false
                
              synchronize(function() --got to check this quickly in the main thread
                --print("mainthread. Checking if Classes is nil")
                if t.Terminated then return end 
                if DataSource.Domains[i].Images[j].Classes==nil then
                  HasToFetchClasses=true
                  DataSource.Domains[i].Images[j].Classes={}
                  DataSource.Domains[i].Images[j].Classes.Busy=true                      
                end
              end)
                
              --classes is now set to busy 
              if HasToFetchClasses then                    
                --print('Getting classes')                  
                DataSource.getClasses(DataSource.Domains[i].Images[j])
                DataSource.Domains[i].Images[j].Classes.Busy=false                      
              end
              
              local classlist
              if filteredList then
                classlist=filteredList
              else
                classlist=DataSource.Domains[i].Images[j].Classes
              end

              for k=currentClassIndex,#classlist do                                    
                if searchtype==0 then 
                  
                  local fullname=classlist[k].FullName
                  if fullname==nil then
                    name=classlist[k].Name
                  end
                  
                  local name=fullname
                    
                  if not caseSensitive then 
                    name=name:upper()
                  end
                  --print(string.format("Checking domain %d image %d class %d (%s)", i,j,k, name))  
                   
                  if name:find(searchInput) then
                    synchronize(function()
                      --add to the list
                      if t.Terminated then return end
                      local li=frmSearch.lvResults.Items.add()
                      li.Caption=DataSource.Domains[i].Images[j].FileName
                      li.SubItems.add(fullname)
                      
                      local e={}
                      e.DomainIndex=i
                      e.ImageIndex=j
                      e.ClassIndex=k
                      searchresults[li.Index+1]=e                     
                                         
                    end)
                  end
                elseif searchtype==1 then
                  --field search  
                  if classlist[k].Fields==nil then                  
                    DataSource.getClassFields(classlist[k])
                  end
                  
                  --print("parsing field list")
                  if classlist[k].Fields then
                    for l=1,#classlist[k].Fields do
                      local name
                      if fieldTypeScan then
                        name=classlist[k].Fields[l].VarTypeName                        
                      else
                        name=classlist[k].Fields[l].Name
                      end
                      
                      if not caseSensitive then 
                        name=name:upper()
                      end
                      
                      if name:find(searchInput) then
                        synchronize(function()
                          if t.Terminated then return end
                          --add to the list
                          local li=frmSearch.lvResults.Items.add()
                          li.Caption=DataSource.Domains[i].Images[j].FileName
                          li.SubItems.add(classlist[k].Name)
                          li.SubItems.add(classlist[k].Fields[l].Name)
                          
                          local e={}
                          e.DomainIndex=i
                          e.ImageIndex=j
                          e.ClassIndex=k
                          e.FieldIndex=l
                          searchresults[li.Index+1]=e                      
                        end)                      
                        
                      end
                    end
                  end
                  
                  
                  
                elseif searchtype==2 then
                  --method search
                  if classlist[k].Methods==nil then
                    DataSource.getClassMethods(classlist[k])                                        
                  end
                  
                  if classlist[k].Methods then
                    for l=1,#classlist[k].Methods do
                      local name
                      if parameterTypeScan then
                        name=classlist[k].Methods[l].Parameters .. ' : '..classlist[k].Methods[l].ReturnType
                      else
                        name=classlist[k].Methods[l].Name
                      end
                      
                      if not caseSensitive then 
                        name=name:upper()
                      end
                      
                      if name:find(searchInput) then
                        synchronize(function()
                          if t.Terminated then return end
                          --add to the list
                          local li=frmSearch.lvResults.Items.add()
                          li.Caption=DataSource.Domains[i].Images[j].FileName
                          li.SubItems.add(classlist[k].Name)
                          li.SubItems.add(classlist[k].Methods[l].Name)
                          
                          local e={}
                          e.DomainIndex=i
                          e.ImageIndex=j
                          e.ClassIndex=k
                          e.MethodIndex=l
                          searchresults[li.Index+1]=e 
                          
                        end) 
                      end
                    end 
                  end                  
                else
                  print("wtf")
                  return --wtf                
                end
                
                if t.Terminated then return end 
                if classScanOnly then break end --break on the class limited scan
                
              end
                
                
              
              if t.Terminated then return end  
              if imageScanOnly or classScanOnly then break end --basescan is the image for classsearch                
            end
            
            if t.Terminated then return end  
            if imageScanOnly or classScanOnly then break end
          end
          
              
           

          --print("End of search thread")
          synchronize(function()
            --print("Synced finish scan")
            currentScan=nil
            if frmSearch~=nil then
              frmSearch.btnScan.Caption='   '..translate('Search')..'   '
            end
          end)
          
          --print("After finish scan sync")
        end)
        
      end
    end
  end  
end



function SearchClassName(classname, onFound, onDone)
  --create a thread that will scan for the given classname and call onFound when found and onNotFound when not
  --if the name is known return a Class instead
 -- printf("SearchClassName for %s", classname)
  if DataSource.ClassNameLookup==nil then
    DataSource.ClassNameLookup={}
  else
    local r=DataSource.ClassNameLookup[classname]
    if r then 
      --printf("Found a class with this name")
      return nil,r
    end
  end
  
  
  return createThread(function(t)
    t.freeOnTerminate(false)
    t.Name='SearchClassName thread'
    function scan()
      local i,j,k
      
      if DataSource.Domains==nil then        
        DataSource.getDomains()
      end      
      
      if t.Terminated then return end
      
      for i=1,#DataSource.Domains do
        if t.Terminated then return end
        
        if DataSource.Domains[i].Images==nil then
          DataSource.getImages(DataSource.Domains[i])
        end
            
        if DataSource.Domains[i].Images==nil then return end
        
        for j=1,#DataSource.Domains[i].Images do
          if t.Terminated then return end
          
          if DataSource.Domains[i].Images[j].Classes==nil then
            DataSource.Domains[i].Images[j].Classes={}
            DataSource.Domains[i].Images[j].Classes.Busy=true 
            DataSource.getClasses(DataSource.Domains[i].Images[j])
            DataSource.Domains[i].Images[j].Classes.Busy=nil             
          end
          
          if t.Terminated then return end
          
          local found=nil
          if not DataSource.Domains[i].Images[j].ClassNameLookupDone then --skip this if it's already added to the name to class lookup table
            for k=1,#DataSource.Domains[i].Images[j].Classes do
              local fullname=DataSource.Domains[i].Images[j].Classes[k].FullName
              
              DataSource.ClassNameLookup[fullname]=DataSource.Domains[i].Images[j].Classes[k]
              
              if (found==nil) and (fullname==classname) then
                found=DataSource.Domains[i].Images[j].Classes[k]
               -- print("found a result")
                if onFound then
                  queue(function()
                    onFound(found)
                  end)                                   
                 
                end
            
              end
            end 
            
            DataSource.Domains[i].Images[j].ClassNameLookupDone=true
          end
          if found then 
            return
          end          
        end
      end
      
     -- print("not found")      
    end
    scan()
    
    synchronize(function()
      if t.Terminated==false then
        onDone()
      end
    end)
  end)
 
  
end
