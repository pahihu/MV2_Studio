unit Unit5;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, ComCtrls,
  M_extras ;

type

  { TSetUPForm }

  TSetUPForm = class(TForm)
    Button1: TButton;
    MTstepCB: TCheckBox;
    RTNbckCB: TCheckBox;
    procedure Button1Click(Sender: TObject);
    procedure FormActivate(Sender: TObject);
  private

  public

  end;

var
  SetUPForm: TSetUPForm;
   ConF:Textfile;
   dirs:String;
   C_ID: array[1..100] of String;

implementation

Uses Unit1;

{$R *.lfm}

{ TSetUPForm }

procedure TSetUPForm.FormActivate(Sender: TObject);
var ix:Integer;
    s1,s2,sc,line:String;
    fileex:Boolean;
begin
 { MV2_Studio.cpf config file Opening}
 {$IFDEF WINDOWS}
  GetDir(0,dirs);
 {$ENDIF}
 {$IFDEF DARWIN}
  dirs:=GetAppConfigDir(False); ForceDirectories(dirs);
 {$ENDIF}
 {$IFDEF LINUX}
 GetDir(0,dirs);
 {$ENDIF}
 fileex:=True; ix:=1;  { MS-Windows version !}
 AssignFile(ConF, dirs + DirectorySeparator + 'MV2_Studio.cpf');
 {$I-} Reset(ConF); {$I+}
 if IOResult <> 0 then fileex:=False;
 If fileex then begin
  CloseFile(ConF);
  Reset(ConF);
  while not Eof(ConF) do begin
   Readln(ConF, line);
   { 1pos=';' Skip  ,  Else proceed... }
   if EX(line,1)<>';' then begin
    s1:=PC(line,':',1); s2:=PC(line,':',2);
    { GEN: General Parameters of MV2-Studio }
    if s1='GEN' then begin
     sc:=PC(s2,';',1);
     if sc='1' then SetUPForm.MTstepCB.Checked:=True else SetUPForm.MTstepCB.Checked:=False;
     sc:=PC(s2,';',2);
     if sc='1' then SetUPForm.RTNbckCB.Checked:=True else SetUPForm.RTNbckCB.Checked:=False;
    end;   { if GEN }
    if FD(s1,'C')=True then begin
     C_ID[ix]:=line; ix:=ix+1   { Save String Array.. }
    end; { if Cxx: }
   end;  { if EX(... }
  end; { While }
  CloseFile(ConF);
 end; { if fileex }
end;

procedure TSetUPForm.Button1Click(Sender: TObject);
var ix:Integer;
    ss,cb1,cb2:String;
begin
  { Save Config File : }
 Rewrite(ConF);
 { Write HEAD INFORMATION }
 Writeln(ConF, ';=============================================');
 Writeln(ConF, ';GEN:Time_Stamp=0/1;Backup_File=0/1;');
 Writeln(ConF, ';Cx:HOST_IP;HOST_Port;DB_name;UCI;DB_encoding;');
 Writeln(ConF, ';');
 Writeln(ConF, ';=============================================');
 { Write GEN: General Parameters }
 cb1:='0'; cb2:='0';
 if MTstepCB.Checked=True then cb1:='1';
 if RTNbckCB.Checked=True then cb2:='1';
 Writeln(ConF, 'GEN:'+cb1+';'+cb2+';');
 StudioForm.GENlb.caption:=cb1+';'+cb2+';';
 { Write Cxx: Connection Parameters }
 for ix:=1 to 100 do begin
  ss:=C_ID[ix];
  if ss<>'' then  Writeln(ConF, ss);
 end;
 CloseFile(ConF);
 MessageDlg('MV2_Studio.cpf save: ' + dirs+'\MV2_Studio.cpf', mtInformation, [mbOk] , 0);
 SetUPForm.Close;
end;

end.

