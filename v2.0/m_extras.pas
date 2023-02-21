unit M_extras;

{ This Unit implemented some MUMPS Standard Function's  }
{ ===================================================== }
{ Free-GPL licensed                       CaIS(c)-2023  }
{ ===================================================== }

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils;

function PC(S:String ; D:String ; P:Integer):String;            {_Piece}
function EX(S:String ; P1:Integer ; P2:Integer=0):String;       {_Extract}
function TR(S:String ; S1:String ; S2:String):String;           {_TRanslate}
function JS(S:String ; P1:Integer ; P2:Integer=0):String;       {_Justify}
function FD(S:String ; S1:String):Boolean;                      {_Find}
function FN(Nr:String ; Fm:String ; Fr:Byte=0):String;          {_FNumber}

implementation

function PC(S:String;D:String;P:Integer):String;
{-------------------------------------------------}
{ MUMPS:    $P("ABC#12.3#45#OK","#",2) => "12.3"  }
{ LAZARUS:  PC('ABC#12.3#45#OK','#',2) => '12.3'  }
{-------------------------------------------------}
var ix,p1,p2:SizeInt;
begin
  p1:=0; p2:=0;
  for ix:=1 to P do begin
    p1:=p2; p2:=Pos(D,S,p1+1);
  end;
  if p1>0 then p1:=p1+1;
  if p1=0 then p1:=1;
  if p2=0 then p2:=Length(S)+1 ;
  result:=Copy(S,p1,(p2-p1));
end;

function EX(S:String;P1:Integer;P2:Integer=0):String;
{-------------------------------------------------}
{ MUMPS:    $E("ABC123OK",2) => "B"               }
{           $E("ABC123OK",2,5) => "BC12"          }
{ LAZARUS:  EX('ABC123OK',2) => 'B'               }
{           EX('ABC123OK',2,5) => 'BC12'          }
{-------------------------------------------------}
begin
  if P2=0 then P2:=1 else P2:=P2-P1+1;
  result:=Copy(S,P1,P2);
end;

function TR(S:String ; S1:String ; S2:String):String;
{---------------------------------------------------------}
{ MUMPS:    $TR("10.10.68.02",".0","|*") => "1*|1*|68|*2" }
{ LAZARUS:  TR('10.10.68.02','.0','|*') => '1*|1*|68|*2'  }
{---------------------------------------------------------}
var ch1,ch2,chs,newS:String;
    ix,xx:Integer;
begin
  for ix:=1 to Length(S1) do begin
   ch1:=EX(S1,ix); newS:='';
   if Length(S2)>0 then ch2:=EX(S2,ix) else ch2:='';
   for xx:=1 to Length(S) do begin
    chs:=EX(S,xx);
    if chs=ch1 then chs:=ch2;
    newS:=newS+chs;
   end; { for xx..}
   S:=newS;
  end; { for ix..}
  result:=newS;
end;

function JS(S:String ; P1:Integer ; P2:Integer=0):String;
{----------------------------------------------}
{ MUMPS:    $J("5200.3489",8,2) => " 5200.35"  }
{ LAZARUS:  JS('5200.3489',8,2) => ' 5200.35'  }
{           JS("5200.3489",8)   => '    5200'  }
{----------------------------------------------}
var bl,rS,nS,nS1,nS2,rch,rchn:String;
    ix,pp,nrch,nrchn:integer;
begin
  rS:=''; nS:=TR(S,',','.'); nS1:=''; nS2:=''; bl:=''; rch:=''; rchn:='';
  if FD(nS,'.')=True then begin
   pp:=Pos('.',nS);
   nS1:=EX(nS,1,pp-1);
   nS2:=EX(nS,pp+1,Length(nS));
  end;
  if P2=0 then nS2:='';
  if P2>0 then begin
   rch:=EX(nS2,P2); nrch:=StrToInt(rch);
   rchn:=EX(nS2,P2+1); nrchn:=StrToInt(rchn);
   if nrchn>4 then nrch:=nrch+1;
   ns2:=EX(ns2,1,P2-1)+IntToStr(nrch);
  end;
  if nS2='' then nS:=nS1 else nS:=nS1+'.'+nS2;
  if Length(nS)<P1 then begin
   for ix:=1 to (P1-Length(nS)) do bl:=bl+chr(32);
   rS:=bl+nS;
  end;
  result:=rS;
end;

function FD(S:String ; S1:String):Boolean;
{------------------------------------------}
{ MUMPS:    $F("APPLE","E") => True($T=1)  }
{ LAZARUS:  FD('APPLE','E') => True        }
{           FD('APPLE','X') => False       }
{------------------------------------------}
var res:Boolean;
begin
  res:=False;  if Pos(S1,S)>0 then res:=True;
  result:=res;
end;

function FN(Nr:String ; Fm:String ; Fr:Byte=0):String;
{----------------------------------------------------------}
{ MUMPS:    $FN("2500600.3489","T+,2") => "2,500,600.35+"  }
{           ......                                         }
{ LAZARUS:  FN('2500600.3489','T+,2')  => '2,500,600.35+'  }
{           FN('2500600.3489','+,2')   => '+2,500,600.35'  }
{           FN('2500600.3489',',2')    => '2,500,600.35'   }
{           FN('2500600.3489','.2')    => '2.500.600,35'   }
{           FN('2500600.3489','_2')    => '2 500 600,35'   }
{           FN('2500600.3489','T+_,2') => '2 500 600,35+'  }
{           FN('2500600.3489','+_2')   => '+2 500 600,35'  }
{----------------------------------------------------------}
var nS,nS1,nS3,nS2,rch,rchn,elj,eljs,delj,delt:String;
      ix,ix3,pp,nrch,nrchn,ppP,ppT:integer;
begin
  nS:=TR(Nr,',','.'); nS1:=''; nS2:=''; nS3:=''; elj:='+'; eljs:=''; delj:=''; delt:='.';
  { Check First char = '+/-' ?? }
  rch:=EX(nS,1);
  if rch='-' then begin
   elj:='-';
   nS:=EX(nS,2,Length(nS));
  end;
  if rch='+' then begin
   elj:='+';
   nS:=EX(nS,2,Length(nS));
  end;
  { Looking the '.' decimal point ! }
  if FD(nS,'.')=True then begin
   pp:=Pos('.',nS);
   nS1:=EX(nS,1,pp-1);
   nS2:=EX(nS,pp+1,Length(nS));
  end;
  if Fr=0 then nS2:='';
  if Fr>0 then begin
   rch:=EX(nS2,Fr); nrch:=StrToInt(rch);
   rchn:=EX(nS2,Fr+1); nrchn:=StrToInt(rchn);
   if nrchn>4 then nrch:=nrch+1;
   ns2:=EX(ns2,1,Fr-1)+IntToStr(nrch);
  end;
  { Format: . ==> xx.xxx.xxx,xx }
  pp:=Pos('.',Fm); if pp>0 then begin
   delj:='.';
   delt:=',';
  end;
  { Format: , ==> xx,xxx,xxx.xx }
  pp:=Pos(',',Fm); if pp>0 then begin
   delj:=',';
   delt:='.';
  end;
  { Format: _ ==> xx xxx xxx,xx }
  pp:=Pos('_',Fm); if pp>0 then begin
   delj:=' ';
   delt:=',';
  end;
  ix3:=0; nS3:='';
  for ix:=Length(nS1) downto 1 do begin
   rch:=EX(nS,ix); ix3:=ix3+1; nS3:=nS3+rch;
   if ix3=3 then begin
    nS3:=nS3+delj;
    ix3:=0;
   end;  { ix3=3 }
  end;  { for nS1 downto }
  nS1:='';
  for ix:=Length(nS3) downto 1 do begin
   rch:=EX(nS3,ix);
   nS1:=nS1+rch;
  end;  { for nS3 downto }
  ppP:=Pos('+',Fm); ppT:=Pos('T',Fm);
  if nS2='' then nS:=nS1 else nS:=nS1+delt+nS2;
  if elj='-' then eljs:=elj;
  if ppP>0 then eljs:=elj;
  if ppT>0 then nS:=nS+eljs else nS:=eljs+nS;
  result:=nS;
end;

end.

