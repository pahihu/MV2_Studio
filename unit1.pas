unit Unit1;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, ComCtrls,
  Buttons, ExtCtrls, IdTCPClient, IdGlobal, SynEdit, SynHighlighterVB, SynHighlighterAny,
  SynHighlighterPython, SynHighlighterSQL, SynHighlighterPHP, SynHighlighterXML,
  SynHighlighterCss, SynHighlighterPo, SynHighlighterPerl, SynHighlighterJava,
  Unit2, Unit3, Unit4, M_extras;

type

  { TStudioForm }

  TStudioForm = class(TForm)
    Button1: TButton;
    AboutBT: TButton;
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
    SCPBar: TProgressBar;
    RTNName: TEdit;
    SYNBtn: TSpeedButton;
    SynMUMPSSyn: TSynAnySyn;
    procedure AboutBTClick(Sender: TObject);
    procedure Button1Click(Sender: TObject);
    procedure FormActivate(Sender: TObject);
    procedure FormResize(Sender: TObject);
    procedure SYNBtnClick(Sender: TObject);
    function TCPSR(msg:String):String;
    procedure Connect(Sender: TObject);
  private

  public

  end;

var
  StudioForm: TStudioForm;

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

procedure TStudioForm.SYNBtnClick(Sender: TObject);
var ANS,enc,UCIDB,srctx,mode:String;
    ix,ixsrc,MX:Integer;
    prb:Real;
begin
  if HOSTUCI.Text='' then MessageDlg('HOST_DB or HOST_UCI not selected! ' ,mtError, mbOKCancel, 0);
  if HOSTUCI.Text='' then Abort;
  UCIDB:=TR(HOSTUCI.Text,'"','~');
  Connect(Sender);
  if MJOB.Text<>'' then begin
   { Set Encoding to IPServer}
   if OpenForm.HOSTUCIENC.Text='' then OpenForm.HOSTUCIENC.Text:='1 = no conversion (Server=Client)';
   enc:=TR(PC(OpenForm.HOSTUCIENC.Text,'=',1),' ','');
   ANS:=StudioForm.TCPSR('CALL|'+MJOB.Text+'|MGR|$$SENC^%MStudio("'+enc+'")');
   { Save Routine Source lines... }
   MX:=CodeEditor.Lines.Count;
   SCPBar.Position:=1;
   for ix:=0 to MX do begin
    srctx:=CodeEditor.Lines[ix]; ixsrc:=ix+1;
    { Decode spec.MUMPS string char & %CaIPS/%CaIPSRV delimiter char }
    {     "=Char(34) ==> Char(96)   |=Chr(124) ==> Chr(127)         }
    srctx:=TR(srctx,'"',chr(96));
    srctx:=TR(srctx,'|',chr(127));
    //SAVE^%MStudio(mode,ucidb,rtn,seq,srctx)
    mode:='!';
    ANS:=TCPSR('CALL|'+MJOB.Text+'|MGR|$$SAVE^%MStudio("'+mode+'","'+UCIDB+'","'+RTNName.Text+'",'+IntToStr(ixsrc)+',"'+srctx+'")');
    prb:=ix/MX*100;
    SCPBar.Position:=Round(prb);
   end; { for CodeEditor.Line[ix].. }
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
  OpenForm.ShowModal;
end;

procedure TStudioForm.AboutBTClick(Sender: TObject);
begin
  AboutForm.ShowModal;
end;

procedure TStudioForm.FormActivate(Sender: TObject);
begin
  StudioForm.Caption:='MV2-Studio  ver: '+AboutForm.GetVersion(Sender);
end;

end.

