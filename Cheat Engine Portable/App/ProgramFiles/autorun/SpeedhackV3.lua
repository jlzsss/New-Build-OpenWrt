--Copyright Cheat Engine

--local 
UnityEngineTimeSetTimeScaleMethod=nil

function getOriginalCodeAndFiller(address, farjmp)
  local original,filler

  if type(address)~='number' then
    address=getAddressSafe(address)
  end

  if address==nil then
    return nil, 'invalid address'
  end

  local sl=createStringList()
  local d=createDisassembler()
  local size=0
  local jmpsize=not farjmp and 5 or 14
  
  
  while size<jmpsize do
    d.disassemble(address)
    local ldd=d.LastDisassembleData
    local inst=ldd.opcode..' '..ldd.parameters
    sl.add(inst)
    size=size+#ldd.bytes
    address=address+#ldd.bytes
  end

  original=sl.Text
  if size-jmpsize>0 then
    filler=string.format("nop %x", size-jmpsize)
  else
    filler=''
  end

  sl.destroy()
  d.destroy()
  return original,filler
end


function hookSpeedFunctions()
  --print("hookSpeedFunctions")
  if getAddressSafe("speedhack_wantedspeed")~=nil then
  --  print("already hooked")
    return true
  end
  
  UnityEngineTimeSetTimeScaleMethod=nil
  
  local r,r2=injectCEHelperLib()
  
  if not r then
    messageDialog('error in injectCEHelperLib(): '..r2, mtError,mbOK)
    return false
  end
  
  local result, data=autoAssemble([[
    globalalloc(speedhack_wantedspeed,4)
    speedhack_wantedspeed:
    dd (float)1
    
    globalalloc(speedhack_unityspeedhackmethod,4)
    speedhack_unityspeedhackmethod:
    dd 1
{$asm}

  ]])

  if not result then
    messageDialog(data)
    return
  end

 -- print("allocated speedhack_wantedspeed")
 
  if monoSettings.Value["SkipMonoSpeedhack"]~='1' then
    local hasMono=getAddressSafe('mono_thread_attach',false,true) or getAddressSafe('il2cpp_thread_attach',false,true)

    if hasMono then
      LaunchMonoDataCollector()
      
      local r=mono_findClass("UnityEngine","Time")
      if r then

        UnityEngineTimeSetTimeScaleMethod=mono_class_findMethod(r,"set_timeScale")
        if UnityEngineTimeSetTimeScaleMethod then    

          local set_timeScale
 
          
          if mono_isil2cpp() then
            set_timeScale=mono_compile_method(UnityEngineTimeSetTimeScaleMethod)
          else          
            set_timeScale=getAddressSafe("UnityEngine.Time:set_timeScale")
          end 
          
          if set_timeScale then   
            local originalcode,filler=getOriginalCodeAndFiller(set_timeScale, true)
          
            if originalcode then            
              local s=string.format([[
{$c}  
extern int speedhack_unityspeedhackmethod; 
extern float speedhack_wantedspeed;
float getNewSpeed(float newspeed)
{
  float wanted=speedhack_wantedspeed; //bug in tcc needs local first
  int method=speedhack_unityspeedhackmethod;
  
  if (method==0) //method 0 : If speed==0, return 0, else return the speedhack speed
  {
    if (newspeed>0)
      newspeed=wanted;    
  }
  else //method 1: multiply the wanted speed by the speedhack speed. 0*wanted==0, 1*wanted=speedhack speed, 2*wanted=double speedhack speed.  Only issue is if it where to read the old speed and apply it's own multiplication
    newspeed=newspeed*wanted;

  return newspeed;
}
{$asm}
alloc(set_timeScaleEntryHook,128)
registersymbol(set_timeScaleEntryHook)
label(returnhere)
set_timeScaleEntryHook:
sub rsp,20
call getNewSpeed //will change xmm0
add rsp,20


//previous version's implementation
 // mov rax,speedhack_wantedspeed 
//  movss xmm0,[rax]

%s
jmp returnhere

%x:
jmp far set_timeScaleEntryHook
%s

returnhere:]], originalcode, set_timeScale, filler) 
              local r,err=autoAssemble(s)
              if r then return true end --just this should be enough
 
              --print(s)
              
              return true
            end
          end
        else
          print("no UnityEngineTimeSetTimeScaleMethod")
        end
      end
    end
  end
  
    

  local gtcaddress=getAddressSafe('kernel32.gettickcount64')
  if gtcaddress==nil then
    waitforExports()
    gtcaddress=getAddressSafe('kernel32.gettickcount64')

    if (gtcaddress==nil) then
      reinitializeSymbolhandler()
      gtcaddress=getAddressSafe('kernel32.gettickcount64')
      if (gtcaddress==nil) then
        messageDialog('Failure finding kernel32.gettickcount64', mtError, mbOK)
        return false
      end
    end
  end


  local originalcode,filler=getOriginalCodeAndFiller(gtcaddress)

  if originalcode then
    local s=string.format([[

alloc(gtc_originalcode,64,"kernel32.gettickcount64")
label(gtc_returnhere)
label(gtchook_exit)

{$c}

#include <stdint.h>
#include <stddef.h>
#include <celib.h>
#include <windowslite.h>

__stdcall uint64_t gtc_originalcode(void);
float gtc_speed=1.0f;
uint64_t gtc_initialtime=0;
uint64_t gtc_initialoffset=0;
CRITICAL_SECTION gtc_cs;

void *gtc_initonce=(void*)0;
int gtc_intialized=0;


extern float speedhack_wantedspeed;

__stdcall int InitOnceExecuteOnce(void *InitOnce, void* InitFn, void* Parameter, void *Context);


__stdcall int initgtc_cs(void *InitOnce, void *Parameter, void *lpContext) {
  InitializeCriticalSection(&gtc_cs);
  gtc_intialized=1;
  return TRUE;
}



__stdcall uint64_t new_gettickcount(void)
{
  uint64_t newtime;

  uint64_t currenttime;
  float wantedspeed; //small issue with tcc where you can not compare against extern directly


  currenttime=gtc_originalcode();

  if (gtc_intialized==0) //only set to true once the cs has been initialized
    InitOnceExecuteOnce(&gtc_initonce, initgtc_cs, NULL, NULL);

  //after here, gtc_cs is initialized
  EnterCriticalSection(&gtc_cs);




  //csenter(&gtc_cs);
  wantedspeed=speedhack_wantedspeed;

  if (gtc_initialtime==0)
  {
    gtc_initialtime=currenttime;
    gtc_initialoffset=currenttime;
  }

  newtime=(currenttime-gtc_initialtime)*gtc_speed;
  newtime=newtime+gtc_initialoffset; //don't put in in the calculation above, as it gets converted to float, and truncated

  if (gtc_speed!=wantedspeed)
  {
    //the user wants to change the speed
    gtc_initialoffset=newtime;
    gtc_initialtime=currenttime;
    gtc_speed=speedhack_wantedspeed;
  }



  LeaveCriticalSection(&gtc_cs);


  return newtime;

}
{$asm}


gtc_originalcode:
%s

gtchook_exit:
jmp gtc_returnhere

kernel32.gettickcount64:
jmp new_gettickcount
%s

gtc_returnhere:

{$ifdef kernel32.timegettime}
kernel32.timeGetTime:
jmp new_gettickcount
{$endif}

kernel32.getTickCount:
jmp new_gettickcount

]],originalcode, filler)

    local result, data=autoAssemble(s) 

    if not result then
      if data==nil then
        data=' (no reason)'
      end
      messageDialog('Failure hooking kernel32.gettickcount64:'..data, mtError, mbOK)
    end
  end;


--queryPerformanceCounter
  local qpcaddress=getAddressSafe('ntdll.RtlQueryPerformanceCounter')
  if qpcaddress==nil then
    waitforExports()
    qpcaddress=getAddressSafe('ntdll.RtlQueryPerformanceCounter')

    if (qpcaddress==nil) then
      reinitializeSymbolhandler()
      qpcaddress=getAddressSafe('ntdll.RtlQueryPerformanceCounter')
      if (qpcaddress==nil) then
        messageDialog('Failure finding kernel32.gettickcount64', mtError, mbOK)
        return false
      end
    end
  end


  local originalcode,filler=getOriginalCodeAndFiller(qpcaddress)

  if originalcode then


  --speedhack does not disable. Just sets speed to 1 when done

    local s=string.format([[

alloc(qpc_originalcode,64,"ntdll.RtlQueryPerformanceCounter")
label(qpc_returnhere)
label(qpchook_exit)

{$c}
#include <stdint.h>
#include <stddef.h>
#include <celib.h>
#include <windowslite.h>


__stdcall int  qpc_originalcode(uint64_t *count);
float qpc_speed=1.0f;
uint64_t qpc_initialtime=0;
uint64_t qpc_initialoffset=0;
CRITICAL_SECTION qpc_cs;

void *qpc_initonce=(void*)0;
int qpc_intialized=0;


uint64_t qpc_lastresult=0;

extern float speedhack_wantedspeed;

__stdcall int InitOnceExecuteOnce(void *InitOnce, void* InitFn, void* Parameter, void *Context);


__stdcall int initqpc_cs(void *InitOnce, void *Parameter, void *lpContext) {
  InitializeCriticalSection(&qpc_cs);
  qpc_intialized=1;
  return TRUE;
}





__stdcall int  new_RtlQueryPerformanceCounter(uint64_t *count)
{
  uint64_t newtime;

  uint64_t currenttime;
  uint64_t newwantedspeed;


  float wantedspeed; //small issue with tcc where you can not compare against extern directly

  if (qpc_intialized==0) //only set to true once the cs has been initialized
    InitOnceExecuteOnce(&qpc_initonce, initqpc_cs, NULL, NULL);

  //after here, gtc_cs is initialized
  EnterCriticalSection(&qpc_cs);


  int result=qpc_originalcode(&currenttime);


  
  
  wantedspeed=speedhack_wantedspeed;

  if (qpc_initialtime==0)
  {
    qpc_initialtime=currenttime;
    qpc_initialoffset=currenttime;
  }

  newtime=(currenttime-qpc_initialtime)*qpc_speed;

  newtime=newtime+qpc_initialoffset;
  if (qpc_speed!=wantedspeed)
  {
    //the user wants to change the speed
    qpc_initialoffset=newtime;
    qpc_initialtime=currenttime;
    qpc_speed=speedhack_wantedspeed;
  }
  
  LeaveCriticalSection(&qpc_cs);

  

  *count=newtime;

  return result;

}
{$asm}


qpc_originalcode:
%s

qpchook_exit:
jmp qpc_returnhere

ntdll.RtlQueryPerformanceCounter:
jmp new_RtlQueryPerformanceCounter
%s

qpc_returnhere:


]],originalcode, filler)

    local result2, data2=autoAssemble(s)
    
    if not result2 then
      if data2==nil then
        data2=' (no reason)'
      end
      messageDialog('Failure hooking ntdll.RtlQueryPerformanceCounter:'..data2, mtError, mbOK)
    end
    
  end;

  return result or result2
end



registerSpeedhackCallbacks(function() --OnActivate
  if (not isConnectedToCEServer()) and targetIsX86() then
    local result, errormsg
    
    
    if getAddressSafe("speedhack_wantedspeed")==nil then
      --still needs hooking
      result,errormsg=hookSpeedFunctions()
    else
      result=true
    end
        
    return true, result, errormsg
  else
    return false
  end
end,

function(speed) --OnSetSpeed(speed)
  if (not isConnectedToCEServer()) and targetIsX86() then
    local result, errormsg
    if getAddressSafe("new_gettickcount")==nil or getAddressSafe("speedhack_wantedspeed")==nil then

      result,errormsg=hookSpeedFunctions()
      if not result then return true, false, errormsg end
    end

    writeFloat("speedhack_wantedspeed", speed)
    
    if UnityEngineTimeSetTimeScaleMethod then
      mono_invoke_method(nil,UnityEngineTimeSetTimeScaleMethod,nil,{speed}) 
    end
    
    result=true      
    
    return true, true
  else
    return false
  end
end)


