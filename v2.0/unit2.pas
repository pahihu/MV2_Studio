unit Unit2;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, ComCtrls,
  M_extras ;

type

  { TOpenForm }

  TOpenForm = class(TForm)
    ConnectBT: TButton;
    HOSTUCIENC: TComboBox;
    Label10: TLabel;
    Label13: TLabel;
    LoadBT: TButton;
    CTXT: TEdit;
    HOSTDB: TComboBox;
    HOSTUCI: TComboBox;
    HOSTIP: TEdit;
    HOSTPort: TEdit;
    MJOB: TEdit;
    OpenPBar: TProgressBar;
    LoadPBar: TProgressBar;
    RTNEdit: TEdit;
    HOSTSaveBT: TButton;
    ConnectionBox: TComboBox;
    GroupBox1: TGroupBox;
    Label1: TLabel;
    Label11: TLabel;
    Label2: TLabel;
    Label6: TLabel;
    Label7: TLabel;
    Label8: TLabel;
    Label9: TLabel;
    CID: TEdit;
    RTNListBox: TListBox;
    OpenBT: TButton;
    procedure ConnectBTClick(Sender: TObject);
    procedure ConnectionBoxSelect(Sender: TObject);
    procedure FormActivate(Sender: TObject);
    procedure FormClose(Sender: TObject);
    procedure HOSTDBLoad;
    procedure HOSTDBSelect(Sender: TObject);
    procedure HOSTSaveBTClick(Sender: TObject);
    procedure LoadBTClick(Sender: TObject);
    procedure OpenBTClick(Sender: TObject);
    procedure RTNListBoxClick(Sender: TObject);
  private

  public

  end;

var
  OpenForm: TOpenForm;
  ConF:Textfile;
  dirs:String;
  NextC_ID:Integer;
  C_ID: array[1..100] of String;
  GENLine:String;


implementation

Uses Unit1;
{$R *.lfm}

{ TOpenForm }

procedure TOpenForm.OpenBTClick(Sender: TObject);
var ANS,UCIDB,enc:String;
    ix,MX:Integer;
    panel_id:Byte;
    prb:Real;
begin
  { Check connected to any HOST ? }
 if MJOB.Text='' then MessageDlg('Please connect to HOST... !! ' ,mtError, mbOKCancel, 0);
 if MJOB.Text='' then Abort;
  { Load ROUTINE }
 if RTNEdit.Text='' then MessageDlg('No Routine selected !! ' ,mtError, mbOKCancel, 0);
 if RTNEdit.Text='' then Abort;
  UCIDB:='[~'+HOSTUCI.Text+'~,~'+HOSTDB.Text+'~]';
  ANS:=StudioForm.TCPSR('CALL|'+MJOB.Text+'|MGR|$$LRL^%MStudio("'+UCIDB+'","'+RTNEdit.Text+'",-1)');
  if ANS='' then
    if MessageDlg('Question', 'Routine not exist in UCI , Editing as NEW ROUTINE ?', mtConfirmation, [mbYes, mbNo],0) = mrYes then ANS:='1';
  if ANS='' then Abort;
  MX:=StrToInt(ANS);
  { Detect Next FREE panle...}
  panel_id:=StudioForm.SRCNext(RTNEdit.Text,HOSTIP.Text,HOSTPort.Text,TR(UCIDB,'~','"'),HOSTUCIENC.Text);
  if panel_id=0 then MessageDlg('Max. source Panel limit ['+IntToStr(StudioForm.MAXP)+'] excide !!' ,mtError, mbOKCancel, 0);
  if panel_id=0 then Abort;
  enc:=TR(PC(HOSTUCIENC.Text,'=',1),' ','');
  ANS:=StudioForm.TCPSR('CALL|'+MJOB.Text+'|MGR|$$SENC^%MStudio("'+enc+'")');
  OpenPBar.Position:=1;
  OpenPBar.Visible:=True;
  for ix:=1 to MX do begin
    ANS:=StudioForm.TCPSR('CALL|'+MJOB.Text+'|MGR|$$LRL^%MStudio("'+UCIDB+'","'+RTNEdit.Text+'",'+IntToStr(ix)+')');
    StudioForm.SRCADD_Panel(panel_id,ix,ANS);
    prb:=ix/MX*100;
    OpenPBar.Position:=Round(prb);
  end;
  OpenPBar.Position:=100;
  StudioForm.LOAD_Panel(Self);
  { Detect MUMPS environment_version }
  StudioForm.HOSTENV.Text:=StudioForm.TCPSR('CALL|'+MJOB.Text+'|MGR|$$DBQ^%MStudio("V")');
  { Close Connection }
  if MJOB.Text<>'' then ConnectBTClick(Sender);
  RTNListBox.Clear;
  StudioForm.MJOB.Text:='--';
  StudioForm.RTNName.Text:=RTNEdit.Text;
  OpenPBar.Visible:=False;
  { BACKUP file options checking }
  if PC(StudioForm.GENlb.Caption,';',2)='1' then StudioForm.BCKFile(IntToStr(panel_id)+'_'+RTNEdit.Text+'_Open.bck');
  RTNEdit.Text:='';
  OpenForm.Close;
end;

procedure TOpenForm.ConnectBTClick(Sender: TObject);
var jobID:String;
begin
  if (HOSTIP.Text='')Or(HOSTPort.Text='') then begin
   MessageDlg('HOST parameter missing (IP/Port)! ' ,mtError, mbOKCancel, 0);
   Abort;
  end;
  StudioForm.CaIPSRV.Host := HOSTIP.Text;
  StudioForm.CaIPSRV.Port := StrToInt(HOSTPort.Text);
  if ConnectBT.Caption='Connect' then begin
   Try
    StudioForm.CaIPSRV.Connect;
    ConnectBT.Caption:='Disconnect';
    CTXT.Text:='Client connected with server ...';
   Except
    on E: Exception do begin
      MessageDlg('CaIS(c)-CaIPSRV CONNECTION ERROR! ' + E.Message,mtError, mbOKCancel, 0);
      CTXT.Text:='Client connection failed to ' + HOSTIP.Text + ':' + HOSTPort.Text;
      ConnectBT.Caption:='Connect';
    end;
   end;
  end { -- Connect -- }
  else begin
    if MJOB.Text<>'' then jobID:=StudioForm.TCPSR('DISCONNECT|'+MJOB.Text);
    StudioForm.CaIPSRV.Disconnect;
    ConnectBT.Caption:='Connect';
    CTXT.Text:='Client disconnected from server !';
    MJOB.Text:='';
  end; { -- Disconnect -- }
  { If connection OK , Get a $J from MV2 server ... }
  if ConnectBT.Caption='Disconnect' then begin
   jobID:=StudioForm.TCPSR('CONNECT');
   CTXT.Text:='Client connected : '+jobID;
   MJOB.Text:=PC(jobID,'=',2);
   HOSTDBLoad;
   HOSTDBSelect(Self);
  end;
end;

procedure TOpenForm.ConnectionBoxSelect(Sender: TObject);
var ss,s1,s2:String;
    sx:Integer;
begin
 ss:=ConnectionBox.Text;
 if ss<>'' then begin
  s1:=TR(PC(ss,':',1),' ','');
  sx:=StrToInt(TR(s1,'C',''));
  s2:=C_ID[sx];
  HOSTIP.Text:=PC(s2,';',1); HOSTPort.Text:=PC(s2,';',2);
  HOSTDB.Text:=PC(s2,';',3); HOSTUCI.Text:=PC(s2,';',4);
  HOSTUCIENC.Text:=PC(s2,';',5); CID.Text:=IntToStr(sx);
 end;
end;

procedure TOpenForm.FormActivate(Sender: TObject);
var ix,sx:Integer;
    s1,s2,sc,line,BL:String;
    fileex:Boolean;
begin
 ConnectionBox.Items.Clear;
 ConnectionBox.Text:=''; HOSTIP.Text:=''; HOSTPort.Text:=''; HOSTDB.Text:='';
 HOSTUCI.Text:=''; HOSTUCIENC.Text:='';
 HOSTDB.Items.Clear; HOSTUCI.Items.Clear;
 BL:=''; for ix:=1 to 80 do BL:=BL+' ';   { Make Blank Line }
 for ix:=1 to 100 do C_ID[ix]:='';        { Clean C_ID memory array }
 NextC_ID:=1; CID.Text:=IntToStr(NextC_ID);
 { MV2_Studio.cpf config file Opening}
  dirs:=GetAppConfigDir(False); ForceDirectories(dirs);
 fileex:=True; ix:=0;  { MS-Windows version !}
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
     StudioForm.GENlb.Caption:=s2;
     GENline:=line;
    end;
    { Cxx: Saved Connection parameters => ConnectionBox }
    if FD(s1,'C')=True then begin
     sx:=StrToInt(TR(s1,'C','')); if sx>ix then ix:=sx;
     sc:=s1+' : '+EX(PC(s2,';',1)+':'+PC(s2,';',2)+BL,1,25)+'['+PC(s2,';',4)+','+PC(s2,';',3)+']';
     ConnectionBox.Items.AddText(sc);
     C_ID[sx]:=s2;     { Save String Array.. }
    end;
   end;
  end;
  CloseFile(ConF);
  NextC_ID:=ix+1; CID.Text:=IntToStr(NextC_ID);
 end;
end;


procedure TOpenForm.FormClose(Sender: TObject);
begin
{ Close Connection }
if MJOB.Text<>'' then ConnectBTClick(Sender);
OpenForm.Close;
end;

procedure TOpenForm.HOSTDBLoad;
var ANS:String;
    ix,MX:Integer;
begin
  HOSTDB.Items.Clear;
  if MJOB.Text<>'' then begin
   ANS:=StudioForm.TCPSR('CALL|'+MJOB.Text+'|MGR|$$DBQ^%MStudio("")');
   MX:=StrToInt(ANS);
   for ix:=1 to MX do begin
    ANS:=StudioForm.TCPSR('CALL|'+MJOB.Text+'|MGR|$$MTI^%MStudio('+IntToStr(ix)+')');
    if ANS<>'' then HOSTDB.Items.Add(ANS);
   end; { for ^MTEMP.. }
  end; { If Connect... }
end;

procedure TOpenForm.HOSTDBSelect(Sender: TObject);
var ANS:String;
    ix,MX:Integer;
begin
  HOSTUCI.Items.Clear;
  if (MJOB.Text<>'')and(HOSTDB.Text<>'') then begin
   ANS:=StudioForm.TCPSR('CALL|'+MJOB.Text+'|MGR|$$UCIQ^%MStudio("'+HOSTDB.Text+'")');
   MX:=StrToInt(ANS);
   for ix:=1 to MX do begin
    ANS:=StudioForm.TCPSR('CALL|'+MJOB.Text+'|MGR|$$MTI^%MStudio('+IntToStr(ix)+')');
    if ANS<>'' then HOSTUCI.Items.Add(ANS);
   end; { for ^MTEMP.. }
  end; { If Connect... }
end;

procedure TOpenForm.HOSTSaveBTClick(Sender: TObject);
var ix:Integer;
    s2,ss:String;
begin
 { Save Selected Connection Config to Memory Array[C_ID] }
 ix:=StrToInt(CID.Text);
 s2:=HOSTIP.Text+';'+HOSTPort.Text+';'+HOSTDB.Text+';'+HOSTUCI.Text+';'+HOSTUCIENC.Text+';';
 C_ID[ix]:=s2;
 { Save Config File : }
 Rewrite(ConF);
 { Write HEAD INFORMATION }
 Writeln(ConF, ';=============================================');
 Writeln(ConF, ';GEN:Time_Stamp=0/1;Backup_File=0/1;');
 Writeln(ConF, ';Cx:HOST_IP;HOST_Port;DB_name;UCI;DB_encoding;');
 Writeln(ConF, ';');
 Writeln(ConF, ';=============================================');
 { Write GEN: General Parameters }
 Writeln(ConF, GENline);
 { Write Cxx: Connection Parameters }
 for ix:=1 to 100 do begin
  ss:=C_ID[ix];
  if ss<>'' then  Writeln(ConF, 'C'+IntToStr(ix)+':'+ss);
 end;
 CloseFile(ConF);
 MessageDlg('MV2_Studio.cpf save: ' + dirs+DirectorySeparator+'MV2_Studio.cpf', mtInformation, [mbOk] , 0);
 if MJOB.Text<>'' then ConnectBTClick(Sender);
 FormActivate(Sender);
end;

procedure TOpenForm.LoadBTClick(Sender: TObject);
var ANS,enc,UCIDB:String;
    ix,MX:Integer;
    prb:Real;
begin
  if HOSTUCI.Text='' then MessageDlg('HOST_DB or HOST_UCI not selected! ' ,mtError, mbOKCancel, 0);
  if HOSTUCI.Text='' then Abort;
  RTNListBox.Items.Clear;
  RTNEdit.Text:='';
  UCIDB:='[~'+HOSTUCI.Text+'~,~'+HOSTDB.Text+'~]';
  if MJOB.Text<>'' then begin
   { Set Encoding to IPServer}
   if HOSTUCIENC.Text='' then HOSTUCIENC.Text:='1 = no conversion (Server=Client)';
   enc:=TR(PC(HOSTUCIENC.Text,'=',1),' ','');
   ANS:=StudioForm.TCPSR('CALL|'+MJOB.Text+'|MGR|$$SENC^%MStudio("'+enc+'")');
   { Load RoutineDirectory }
   ANS:=StudioForm.TCPSR('CALL|'+MJOB.Text+'|MGR|$$RTNQ^%MStudio("'+UCIDB+'")');
   MX:=StrToInt(ANS);
   LoadPBar.Position:=1;
   LoadPBar.Visible:=True;
   for ix:=1 to MX do begin
    ANS:=StudioForm.TCPSR('CALL|'+MJOB.Text+'|MGR|$$MTI^%MStudio('+IntToStr(ix)+')');
    if ANS<>'' then RTNListBox.Items.AddText(ANS);
    prb:=ix/MX*100;
    LoadPBar.Position:=Round(prb);
   end; { for ^MTEMP.. }
   LoadPBar.Visible:=False;
  end { If Connect... }
  else MessageDlg('Please Connect to Database ! ' ,mtError, mbOKCancel, 0);
end;

procedure TOpenForm.RTNListBoxClick(Sender: TObject);
var ANS:String;
begin
 ANS:=RTNListBox.GetSelectedText;
 RTNEdit.Text:=TR(PC(ANS,'|',1),' ','');
end;

end.
