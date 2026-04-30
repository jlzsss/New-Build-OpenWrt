function forEachAndFutureForm(classname, func)
  local i
  for i=0,getFormCount()-1 do
    local f
    f=getForm(i)
    if f.ClassName==classname then
      func(f)
    end
  end

  registerFormAddNotification(function(f)
    if classname==f.ClassName then
      f.registerFirstShowCallback(function()
        func(f)
      end)
    end
  end)
end