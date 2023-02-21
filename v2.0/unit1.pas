unit Unit1;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, ComCtrls,
  Buttons, ExtCtrls, IdTCPClient, IdGlobal, SynEdit, SynHighlighterVB, SynHighlighterAny,
  SynHighlighterPython, SynHighlighterSQL, SynHighlighterPHP, SynHighlighterXML,
  SynHighlighterCss, SynHighlighterPo, SynHighlighterPerl, SynHighlighterJava,
  Unit2, Unit3, Unit4, Unit5, Unit6, M_extras, lclintf, LCLtype, SynEditMarkupSpecialLine;

const   MaxCodeLines=5000;
           MaxPanels=8;

type

  { TStudioForm }

  TStudioForm = class(TForm)
    Button1: TButton;
    AboutBT: TButton;
    HOSTENV: TEdit;
    HOSTENC: TEdit;
    GENlb: TLabel;
    RTNLines: TLabel;
    RTNLines1: TLabel;
    SetUp: TImage;
    SRCPanel1img: TImage;
    Label6: TLabel;
    Panel3: TPanel;
    SRCPanel1: TPanel;
    SRCBT: TButton;
    CaIPSRV: TIdTCPClient;
    Image1: TImage;
    MJOB: TEdit;
    Label2: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    HOSTIP: TEdit;
    HOSTPort: TEdit;
    HOSTUCI: TEdit;
    Label5: TLabel;
    Panel1: TPanel;
    CodeEditor: TSynEdit;
    Panel2: TPanel;
    SCPBar: TProgressBar;
    RTNName: TEdit;
    SRCPanel8img: TImage;
    SRCPanel7img: TImage;
    SRCPanel6img: TImage;
    SRCPanel5img: TImage;
    SRCPanel4img: TImage;
    SRCPanel3img: TImage;
    SRCPanel2img: TImage;
    SRCPanel2: TPanel;
    SRCPanel3: TPanel;
    SRCPanel4: TPanel;
    SRCPanel5: TPanel;
    SRCPanel6: TPanel;
    SRCPanel7: TPanel;
    SRCPanel8: TPanel;
    SYNBtn: TSpeedButton;
    SynMUMPSSyn: TSynAnySyn;
    procedure AboutBTClick(Sender: TObject);
    procedure Button1Click(Sender: TObject);
    procedure CodeEditorChange(Sender: TObject);
    procedure CodeEditorKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure CodeEditorSpecialLineColors(Sender: TObject; Line: integer;
      var Special: boolean; var FG, BG: TColor);
    procedure FormActivate(Sender: TObject);
    procedure FormResize(Sender: TObject);
    procedure Image1Click(Sender: TObject);
    procedure SetUpClick(Sender: TObject);
    procedure SRCBTClick(Sender: TObject);
    procedure SRCPanel1imgClick(Sender: TObject);
    procedure SRCPanel1Click(Sender: TObject);
    procedure SYNBtnClick(Sender: TObject);
    function TCPSR(msg:String):String;
    function SRCNext(name_id:String; h_ip:String; h_port:String; ucidb:String; enc:String):Byte;
    procedure SRCADD_Panel(idx:Integer; lix:Integer; txt:String);
    procedure SRCFindLine_ADD(idx:Integer);
    function SRCFindLine_Next(ss:String; idx:Integer):Integer;
    procedure SRC_Replace(ss1:String; ss2:String);
    procedure SRC_WSP(spn:Integer);
    procedure SAVE_Panel(Sender: TObject);
    procedure LOAD_Panel(Sender: TObject);
    procedure CLOSE_Panel(id:String);
    procedure CLEAR_Panel(idx:Integer);
    procedure BCKFile(fnm:String);
    function MAXP:Byte;
    procedure RfrSRCPanels(Sender: TObject);
    procedure Connect(Sender: TObject);
  private

  public

  end;

type
   SRCPanel = record
        name:String;
      HOSTIP:String;
    HOSTPort:String;
       UCIDB:String;
         ENC:String;
      lines : array[1..MaxCodeLines] of string;
     linemx :Integer;
          mf:String;
     TopLine:Integer;
     CurLine:Integer;
end;

var
 StudioForm: TStudioForm;
 SRCPanels: array[1..MaxPanels] of SRCPanel;    { MUMPS Source+info in Memory... }
 SRCActive: Integer;                            { Active SRCPanel_Nr. 1..8 }
SRCFindLine: Integer=0;
  MDTstamp: String;
   BCKfile: String;

 implementation

{$R *.lfm}

{ TStudioForm }

{===================== Indy 10 TCP Client section ============================}
function TStudioForm.TCPSR(msg:String):String;
var
  LLine: String;
  pi : Integer;
  comFlag:Boolean;
begin
  LLine:=''; comFlag:=True;
  { Set Default Indy ENCODING = UTF-8 }
  CaIPSRV.IOHandler.defStringEncoding:=IndyTextEncoding_UTF8;
  Try
  CaIPSRV.IOHandler.WriteLn(msg);
  Except
   on E: Exception do begin
     MessageDlg('CaIS(c) CONNECTION LOST! ' + E.Message,mtError, mbOKCancel, 0);
     ComFlag:=False;
   end;
  End;
  If comFlag = True then begin
    LLine := CaIPSRV.IOHandler.ReadLn();
    LLine:=Copy(LLine,2,Length(LLine)-2);
    pi:=pos('<KILL %MID',LLine);
    if (pi>0) then CaIPSRV.Disconnect;
  end;
  result := LLine;
end;

procedure TStudioForm.Connect(Sender: TObject);
var jobID:String;
    con:Boolean;
begin
  if (HOSTIP.Text='')Or(HOSTPort.Text='') then begin
   MessageDlg('HOST parameter missing (IP/Port)! ' ,mtError, mbOKCancel, 0);
   Abort;
  end;
  CaIPSRV.Host := HOSTIP.Text;
  CaIPSRV.Port := StrToInt(HOSTPort.Text);
  MJOB.Text:=TR(MJOB.Text,'-',''); con:=False;
  if MJOB.Text='' then begin
   Try
    CaIPSRV.Connect;
    con:=True;
   Except
    on E: Exception do begin
      MessageDlg('CaIS(c)-CaIPSRV CONNECTION ERROR! ' + E.Message,mtError, mbOKCancel, 0);
      con:=False;
    end;
   end;
  end { -- Connect -- }
  else begin
    if MJOB.Text<>'' then jobID:=TCPSR('DISCONNECT|'+MJOB.Text);
    CaIPSRV.Disconnect;
    MJOB.Text:=''; con:=False;
  end; { -- Disconnect -- }
  { If connection OK , Get a $J from MV2 server ... }
  if con=True then begin
   jobID:=TCPSR('CONNECT');
   MJOB.Text:=PC(jobID,'=',2);
  end;
end;

{===================== END Of Indy TCP Client section =========================}

procedure TStudioForm.FormResize(Sender: TObject);
begin
  //Automatic Resize CODEEditor box
  CodeEditor.Width:=StudioForm.Width-15;
  CodeEditor.Height:=StudioForm.Height-78;
end;

procedure TStudioForm.Image1Click(Sender: TObject);
begin
  OpenDocument('https://www.lazarus-ide.org/');
end;

procedure TStudioForm.SetUpClick(Sender: TObject);
begin
 SetUPForm.ShowModal;
end;

procedure TStudioForm.SRCBTClick(Sender: TObject);
begin
 if SRCActive=0 then Abort;
 ToolsForm.Showmodal;
end;

procedure TStudioForm.SRCPanel1imgClick(Sender: TObject);
var id:String;
    idx:Integer;
begin
 id:=''; if Sender is TImage then id:=TImage(Sender).Hint;
 idx:=StrToInt(id);
 if SRCPanels[idx].mf='' then CLOSE_Panel(id);
 if SRCPanels[idx].mf<>'' then
   if MessageDlg('Question', SRCPanels[idx].name+' routine changed ! Close without SAVE routine ?', mtConfirmation, [mbYes, mbNo],0) = mrYes then CLOSE_Panel(id);
end;

procedure TStudioForm.SRCPanel1Click(Sender: TObject);
var id:String;
    idn:Integer;
begin
   id:=''; if Sender is TPanel then id:=TPanel(Sender).caption;
   id:=PC(PC(id,']',1),'[',2);
   { Switch to Selected SRCPanel ... }
   idn:=StrToInt(id);
   if idn<>SRCActive then begin
    SAVE_Panel(Self);
    CodeEditor.lines.Clear;
    SRCActive:=idn;
    LOAD_Panel(Self);
    RfrSRCPanels(Self);
   end;
end;

procedure TStudioForm.SYNBtnClick(Sender: TObject);
var ANS,enc,UCIDB,srctx,mode:String;
    ix,ixsrc,MX:Integer;
    prb:Real;
begin
  if PC(GENlb.Caption,';',2)='1' then BCKFile(IntToStr(SRCActive)+'_'+RTNName.Text+'_Save.bck');
  if HOSTUCI.Text='' then MessageDlg('HOST_DB or HOST_UCI not selected! ' ,mtError, mbOKCancel, 0);
  if HOSTUCI.Text='' then Abort;
  UCIDB:=TR(HOSTUCI.Text,'"','~');
  Connect(Sender);
  if MJOB.Text<>'' then begin
   { Set Encoding to IPServer}
   if OpenForm.HOSTUCIENC.Text='' then OpenForm.HOSTUCIENC.Text:='1 = no conversion (Server=Client)';
   enc:=TR(PC(HOSTENC.Text,'=',1),' ','');
   ANS:=StudioForm.TCPSR('CALL|'+MJOB.Text+'|MGR|$$SENC^%MStudio("'+enc+'")');
   { Save Routine Source lines... }
   MX:=CodeEditor.Lines.Count;     { 0..MX-1}
   SCPBar.Position:=1;
   RTNName.Text:=TR(RTNName.Text,'*','');
   { First line prepare... }
    mode:=PC(GENlb.caption,';',1);
    if mode='1' then begin
     srctx:=CodeEditor.Lines[0];
     srctx:=TCPSR('CALL|'+MJOB.Text+'|MGR|$$TS^%MStudio("'+srctx+'")');
     CodeEditor.Lines[0]:=srctx;
    end;
   for ix:=0 to (MX-1) do begin
    srctx:=CodeEditor.Lines[ix]; ixsrc:=ix+1;
    { Decode spec.MUMPS string char & %CaIPS/%CaIPSRV delimiter char }
    {     "=Char(34) ==> Char(96)   |=Chr(124) ==> Chr(127)         }
    srctx:=TR(srctx,'"',chr(96));
    srctx:=TR(srctx,'|',chr(127));
    //SAVE^%MStudio(mode,ucidb,rtn,seq,srctx)
    ANS:=TCPSR('CALL|'+MJOB.Text+'|MGR|$$SAVE^%MStudio("'+UCIDB+'","'+RTNName.Text+'",'+IntToStr(ixsrc)+',"'+srctx+'")');
    prb:=ix/MX*100;
    SCPBar.Position:=Round(prb);
   end; { for CodeEditor.Line[ix].. }
    SCPBar.Position:=100;
   SRCPanels[SRCActive].mf:=''; RfrSRCPanels(Self);
   RTNLines.Caption:=IntToStr(MX);
   { ReCompile }
   ANS:=TCPSR('CALL|'+MJOB.Text+'|MGR|$$COMP^%MStudio("'+UCIDB+'","'+RTNName.Text+'")');
   { Syntax Check & Report error's to Compiler Output }
   ANS:=TCPSR('CALL|'+MJOB.Text+'|MGR|$$SYNCH^%MStudio("'+UCIDB+'","'+RTNName.Text+'")');
   if ANS='OK' then MessageDlg('Routine: '+RTNName.Text+' saved & compiled done [No errors].' ,mtInformation, mbOKCancel, 0)
   else begin
    SYNCHForm.SYNERR.Lines.Clear;
    SYNCHForm.Caption:='Routine: '+RTNName.Text+'     syntax errors:';
    MX:=StrToInt(PC(ANS,':',2));
    for ix:=1 to MX do begin
     ANS:=TCPSR('CALL|'+MJOB.Text+'|MGR|$$MTI^%MStudio('+IntToStr(ix)+')');
     if ANS<>'' then SYNCHForm.SYNERR.Lines.Add(ANS);
    end; { for }
    SYNCHForm.ShowModal;
   end; { else : ERR:xx }
   Connect(Sender);  { Disconnect }
   SCPBar.Position:=0;
  end { If Connect... }
  else MessageDlg('Connection failed !!' ,mtError, mbOKCancel, 0);
end;

procedure TStudioForm.Button1Click(Sender: TObject);
begin
  SRCFindLine:=0;
  OpenForm.ShowModal;
  CodeEditor.SetFocus;
end;

procedure TStudioForm.CodeEditorChange(Sender: TObject);
begin
  if CodeEditor.Lines.Count<>SRCPanels[SRCActive].linemx then begin
   SRCPanels[SRCActive].linemx:=CodeEditor.Lines.Count;
   RTNLines.Caption:=IntToStr(SRCPanels[SRCActive].linemx);
  end;
  if SRCPanels[SRCActive].mf='' then begin
   SRCPanels[SRCActive].mf:='*';
   RTNName.Text:=RTNName.Text+'*';
   RfrSRCPanels(Self);
  end;
end;

procedure TStudioForm.CodeEditorKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
 { CodeEditor  Hot-Keys ... }
 if (Key = VK_S) and (ssCtrl in Shift) then if RTNName.Text<>'' then SYNBtnClick(Self);
 if (Key = VK_F) and (ssCtrl in Shift) then if RTNName.Text<>'' then ToolsForm.ShowModal;
 if (Key = VK_O) and (ssCtrl in Shift) then OpenForm.ShowModal;
end;

procedure TStudioForm.CodeEditorSpecialLineColors(Sender: TObject;
  Line: integer; var Special: boolean; var FG, BG: TColor);
begin
  if Line = SRCFindLine then
  begin
   Special := True;
   BG := clMaroon;
   FG := clWhite;
  end;
end;

procedure TStudioForm.AboutBTClick(Sender: TObject);
begin
  AboutForm.ShowModal;
end;

procedure TStudioForm.FormActivate(Sender: TObject);
var ix,iix:Integer;
begin
  StudioForm.Caption:='MV2-Studio  ver: '+AboutForm.GetVersion(Sender);
  { First Init the SRCPanels array }
  for ix:=1 to MaxPanels do begin
   SRCPanels[ix].name:='';
   SRCPanels[ix].HOSTIP:='';
   SRCPanels[ix].HOSTPort:='';
   SRCPanels[ix].UCIDB:='';
   SRCPanels[ix].ENC:='';
   SRCPanels[ix].mf:='';
   for iix:=1 to MaxCodeLines do SRCPanels[ix].lines[iix]:='';
   SRCPanels[ix].linemx:=0;
  end;
  SRCActive:=0;
  SRCFindLine:=0;
  CodeEditor.SetFocus;
end;

function TStudioForm.SRCNext(name_id:String; h_ip:String; h_port:String; ucidb:String; enc:String):Byte;
var id,ix:Byte;
begin
 id:=0;
 { Looking first empty/free panel... }
 for ix:=1 to MaxPanels do if (SRCPanels[ix].name='') and (id=0) then id:=ix;
 { if SRCActive<>id then SAVE SRCActive panel to Memory array... }
 if (SRCActive<>id) and (SRCActive>0) then begin
  SAVE_Panel(Self);
  CodeEditor.lines.Clear;
 end;
 { Registry If available panel ... }
 if id>0 then begin
  CLEAR_Panel(id);
  SRCPanels[id].name:='['+IntToStr(id)+']'+name_id;
  SRCPanels[id].mf:='';
  SRCPanels[id].HOSTIP:=h_ip;
  SRCPanels[id].HOSTPort:=h_port;
  SRCPanels[id].UCIDB:=ucidb;
  SRCPanels[id].ENC:=enc;
  SRCActive:=id;
  RfrSRCPanels(Self);
 end;
 result:=id;
end;

procedure TStudioForm.SRCADD_Panel(idx:Integer; lix:Integer; txt:String);
begin
 SRCPanels[idx].lines[lix]:=txt;
 SRCPanels[idx].linemx:=lix;
end;

procedure TStudioForm.RfrSRCPanels(Sender: TObject);
var ix:Integer;
    nid:String;
begin
  SRCPanel1.Visible:=False;
  SRCPanel2.Visible:=False;
  SRCPanel3.Visible:=False;
  SRCPanel4.Visible:=False;
  SRCPanel5.Visible:=False;
  SRCPanel6.Visible:=False;
  SRCPanel7.Visible:=False;
  SRCPanel8.Visible:=False;
  for ix:=1 to MaxPanels  do begin
   nid:=SRCPanels[ix].name;
   if nid<>'' then case ix of
    1: begin SRCPanel1.Caption:=SRCPanels[ix].name+SRCPanels[ix].mf; SRCPanel1.Visible:=True; SRCPanel1.Color:=$00EDD9C5; if SRCActive=ix then SRCPanel1.Color:=$00D3A270; end;
    2: begin SRCPanel2.Caption:=SRCPanels[ix].name+SRCPanels[ix].mf; SRCPanel2.Visible:=True; SRCPanel2.Color:=$00EDD9C5; if SRCActive=ix then SRCPanel2.Color:=$00D3A270; end;
    3: begin SRCPanel3.Caption:=SRCPanels[ix].name+SRCPanels[ix].mf; SRCPanel3.Visible:=True; SRCPanel3.Color:=$00EDD9C5; if SRCActive=ix then SRCPanel3.Color:=$00D3A270; end;
    4: begin SRCPanel4.Caption:=SRCPanels[ix].name+SRCPanels[ix].mf; SRCPanel4.Visible:=True; SRCPanel4.Color:=$00EDD9C5; if SRCActive=ix then SRCPanel4.Color:=$00D3A270; end;
    5: begin SRCPanel5.Caption:=SRCPanels[ix].name+SRCPanels[ix].mf; SRCPanel5.Visible:=True; SRCPanel5.Color:=$00EDD9C5; if SRCActive=ix then SRCPanel5.Color:=$00D3A270; end;
    6: begin SRCPanel6.Caption:=SRCPanels[ix].name+SRCPanels[ix].mf; SRCPanel6.Visible:=True; SRCPanel6.Color:=$00EDD9C5; if SRCActive=ix then SRCPanel6.Color:=$00D3A270; end;
    7: begin SRCPanel7.Caption:=SRCPanels[ix].name+SRCPanels[ix].mf; SRCPanel7.Visible:=True; SRCPanel7.Color:=$00EDD9C5; if SRCActive=ix then SRCPanel7.Color:=$00D3A270; end;
    8: begin SRCPanel8.Caption:=SRCPanels[ix].name+SRCPanels[ix].mf; SRCPanel8.Visible:=True; SRCPanel8.Color:=$00EDD9C5; if SRCActive=ix then SRCPanel8.Color:=$00D3A270; end;
   end;
  end;
end;

procedure TStudioForm.SAVE_Panel(Sender: TObject);
var iix,MX,lnx:Integer;
    rtnn:string;
begin
 lnx:=CodeEditor.TopLine;
 SRCPanels[SRCActive].TopLine:=lnx;
 lnx:=CodeEditor.Lines.IndexOf(CodeEditor.LineText)+1; { 0..Mc-1 }
 SRCPanels[SRCActive].CurLine:=lnx;
 for iix:=1 to MaxCodeLines do SRCPanels[SRCActive].lines[iix]:='';
 MX:=CodeEditor.Lines.Count;  { 0..MX-1 }
 for iix:=0 to (MX-1) do SRCPanels[SRCActive].lines[iix+1]:=CodeEditor.Lines[iix];
 SRCPanels[SRCActive].linemx:=MX;
 SRCPanels[SRCActive].mf:='';
 { SAVE HEAD info field's }
 SRCPanels[SRCActive].HOSTIP:=HOSTIP.Text;
 SRCPanels[SRCActive].HOSTPort:=HOSTPort.Text;
 SRCPanels[SRCActive].ENC:=HOSTENC.Text;
 SRCPanels[SRCActive].UCIDB:=HOSTUCI.Text;
 rtnn:=TR(RTNName.Text,'*','');
 SRCPanels[SRCActive].name:='['+IntToStr(SRCActive)+']'+rtnn;
 if FD(RTNName.Text,'*')=True then SRCPanels[SRCActive].mf:='*';
end;

procedure TStudioForm.LOAD_Panel(Sender: TObject);
var iix,MX:Integer;
    srcline:String;
begin
 { Load source/lines from Memory array... }
 CodeEditor.lines.Clear;
 MX:=SRCPanels[SRCActive].linemx;
 RTNLines.Caption:=IntToStr(MX);
 for iix:=1 to MX do begin
  srcline:=SRCPanels[SRCActive].lines[iix];
  CodeEditor.Lines.Add(srcline);
 end;
 { Update HEAD info field's }
 HOSTIP.Text:=SRCPanels[SRCActive].HOSTIP;
 HOSTPort.Text:=SRCPanels[SRCActive].HOSTPort;
 HOSTENC.Text:=SRCPanels[SRCActive].ENC;
 HOSTUCI.Text:=SRCPanels[SRCActive].UCIDB;
 RTNName.Text:=PC(SRCPanels[SRCActive].name,']',2);
 if SRCPanels[SRCActive].mf<>'' then RTNName.Text:=RTNName.Text+'*';
 CodeEditor.TopLine:=SRCPanels[SRCActive].TopLine;
 //CodeEditor.lines.  .GotoBookMark(SRCPanels[SRCActive].CurLine);
 CodeEditor.SetFocus;
end;

procedure TStudioForm.CLOSE_Panel(id:String);
var idx,iix,idmx:Integer;
    nm:String;
begin
 idx:=StrToInt(id); CLEAR_Panel(idx);
 if idx=SRCActive then begin
  CodeEditor.Lines.Clear;
  RTNName.Text:='';
  HOSTIP.Text:='';
  HOSTPort.Text:='';
  HOSTUCI.Text:='';
  HOSTENC.Text:='';
  SRCActive:=1;
 end;
 { looking a max.index of usedPanel }
 idmx:=0; for iix:=1 to MaxPanels do if (SRCPanels[iix].name<>'') and (iix>idmx) then idmx:=iix;
 { if idx<>idmx , then : Re-Ordered Panel index.. }
 if idx<>(idmx+1) then for iix:=1 to idmx do begin
   if (SRCPanels[iix].name='') and (iix<MaxPanels) then begin
    CLEAR_Panel(iix);
    SRCPanels[iix]:=SRCPanels[iix+1];
    { Prepare 'name' [index] }
    nm:=SRCPanels[iix].name;
    if nm<>'' then begin
     nm:=PC(nm,']',2);
     SRCPanels[iix].name:='['+IntToStr(iix)+']'+nm;
    end; { if nm<>'' ... }
    CLEAR_Panel(iix+1);
    if SRCActive=(iix+1) then SRCActive:=iix;
   end; { if }
  end; { for }
 { Refresh Panels... }
 if (idx=1) and (idmx=0) then SRCActive:=0;
 RfrSRCPanels(Self);
 if SRCActive>0 then LOAD_Panel(Self);
end;

procedure TStudioForm.CLEAR_Panel(idx:Integer);
var iix:Integer;
begin
 for iix:=1 to MaxCodeLines do SRCPanels[idx].lines[iix]:='';
 SRCPanels[idx].linemx:=0;
 SRCPanels[idx].mf:='';
 SRCPanels[idx].HOSTIP:='';
 SRCPanels[idx].HOSTPort:='';
 SRCPanels[idx].ENC:='';
 SRCPanels[idx].UCIDB:='';
 SRCPanels[idx].name:='';
 SRCPanels[idx].TopLine:=1;
 SRCPanels[idx].CurLine:=1;
 RTNLines.Caption:='0';
end;

 procedure TStudioForm.BCKFile(fnm:String);
 var ix,MX:Integer;
     dirs:String='';
     opt:String;
     BckF:TextFile;
 begin
  { Save BACKUP File : }
  {$IFDEF WINDOWS}
   GetDir(0,dirs);
  {$ENDIF}
  {$IFDEF DARWIN}
   dirs:=GetAppConfigDir(False); ForceDirectories(dirs);
  {$ENDIF}
  {$IFDEF LINUX}
  GetDir(0,dirs);
  {$ENDIF}
  opt:=' Opening state , before Editing !';
  if FD(fnm,'Save')=True then opt:=' Last Edited state , before connect to HOST...';
  AssignFile(BckF, dirs + DirectorySeparator + fnm);
  Rewrite(BckF);
  { Write HEAD INFORMATION }
  Writeln(BckF, '['+IntToStr(SRCActive)+']'+RTNName.Text+' {Automatic Save : '+opt+'}');
  Writeln(BckF, '-------------------------------------------------------------------------------');
  { Write CodeEditor lines .... }
  MX:=CodeEditor.Lines.Count;
  for ix:=0 to MX do begin
   Writeln(BckF, CodeEditor.lines[ix]);
  end;
  CloseFile(BckF);
 end;

function TStudioForm.MAXP:Byte;
begin
 result:=MaxPanels;
end;

 procedure TStudioForm.SRCFindLine_ADD(idx:Integer);
 begin
  SRCFindLine:=idx;
 end;

 function TStudioForm.SRCFindLine_Next(ss:String; idx:Integer):Integer;
 var mv:Boolean;
     ix,MX,ret:Integer;
 begin
  mv:=False; ret:=0;
  MX:=CodeEditor.lines.count;
  for ix:=0 to (MX-1) do if (ix+1)>idx then if mv=False then if Pos(ss,CodeEditor.lines[ix])>0 then begin
   ret:=ix+1; mv:=True;
  end;
  result:=ret;
 end;

 procedure TStudioForm.SRC_Replace(ss1:String; ss2:String);
 var ix,MX:Integer;
     ss:String;
     mvf:Boolean;
 begin
  MX:=CodeEditor.lines.count; mvf:=False;
  for ix:=0 to (MX-1) do begin
   ss:=CodeEditor.lines[ix];
   if Pos(ss1,ss)>0 then begin
    ss:=StringReplace(ss, ss1, ss2, [rfReplaceAll]);
    mvf:=True;
   end; { if }
   CodeEditor.lines[ix]:=ss;
  end; { for }
  if (mvf=True) and (SRCPanels[SRCActive].mf='') then begin
   SRCPanels[SRCActive].mf:='*';
   RTNName.Text:=RTNName.Text+'*';
   RfrSRCPanels(Self);
  end; { if mvf * }
 end;

 procedure TStudioForm.SRC_WSP(spn:Integer);
 var ix,MX:Integer;
     ss,BL:String;
     mvf:Boolean;
 begin
  BL:=''; for ix:=1 to spn do BL:=BL+' ';   { Make Blank Line }
  MX:=CodeEditor.lines.count; mvf:=False;
  for ix:=0 to (MX-1) do begin
   ss:=CodeEditor.lines[ix];
   if EX(ss,1)=' ' then begin
    ss:=BL+ss; mvf:=True;
   end; { if }
   CodeEditor.lines[ix]:=ss;
  end; { for }
  if (mvf=True) and (SRCPanels[SRCActive].mf='') then begin
   SRCPanels[SRCActive].mf:='*';
   RTNName.Text:=RTNName.Text+'*';
   RfrSRCPanels(Self);
  end; { if mvf * }
 end;

end.

