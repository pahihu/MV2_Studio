unit Unit6;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls, StdCtrls;

type

  { TToolsForm }

  TToolsForm = class(TForm)
    WSPbt: TButton;
    Label3: TLabel;
    SPEdit: TEdit;
    SSEdit: TEdit;
    FNDbt: TButton;
    REPLbt: TButton;
    Label1: TLabel;
    Label2: TLabel;
    Panel1: TPanel;
    RSEdit: TEdit;
    procedure FNDbtClick(Sender: TObject);
    procedure FormActivate(Sender: TObject);
    procedure FormClose(Sender: TObject);
    procedure REPLbtClick(Sender: TObject);
    procedure WSPbtClick(Sender: TObject);
  private

  public

  end;

var
  ToolsForm: TToolsForm;
  FindStart: Integer=0;

implementation

Uses Unit1;

{$R *.lfm}

{ TToolsForm }

procedure TToolsForm.WSPbtClick(Sender: TObject);
var spn:Integer;
begin
  if SPEdit.Text<>'' then begin
    spn:=StrToInt(SPEdit.Text);
    StudioForm.SRC_WSP(spn);
  end;
  ToolsForm.Close;
end;

procedure TToolsForm.REPLbtClick(Sender: TObject);
begin
  StudioForm.SRC_Replace(SSEdit.Text,RSEdit.Text);
  StudioForm.CodeEditor.Refresh;
  StudioForm.CodeEditor.SetFocus;
  ToolsForm.Close;
end;

procedure TToolsForm.FormActivate(Sender: TObject);
begin
  SSEdit.Text:='';
  RSEdit.Text:='';
  SPEdit.Text:='';
  FindStart:=0;
end;

procedure TToolsForm.FormClose(Sender: TObject);
begin
 StudioForm.SRCFindLine_ADD(0);
 StudioForm.CodeEditor.Refresh;
 StudioForm.CodeEditor.SetFocus;
end;

procedure TToolsForm.FNDbtClick(Sender: TObject);
var sii:Integer;
begin
 FindStart:=StudioForm.SRCFindLine_Next(SSEdit.Text,FindStart); sii:=1;
 if FindStart>24 then sii:=FindStart-24;
 StudioForm.SRCFindLine_ADD(FindStart);
 StudioForm.CodeEditor.TopLine:=sii;
 StudioForm.CodeEditor.Refresh;
end;

end.

