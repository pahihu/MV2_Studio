unit Unit3;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, ExtCtrls, lclintf, vinfo;

type

  { TAboutForm }

  TAboutForm = class(TForm)
    Button1: TButton;
    Image1: TImage;
    Image2: TImage;
    Image3: TImage;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    Panel1: TPanel;
    Panel2: TPanel;
    procedure Button1Click(Sender: TObject);
    procedure FormActivate(Sender: TObject);
    function GetVersion(Sender: TObject):String;
    procedure Panel2Click(Sender: TObject);
  private

  public

  end;

var
  AboutForm: TAboutForm;

implementation

{$R *.lfm}

{ TAboutForm }

procedure TAboutForm.Button1Click(Sender: TObject);
begin
  AboutForm.Close;
end;

procedure TAboutForm.FormActivate(Sender: TObject);
begin
  Label2.Caption:='Version: '+GetVersion(Sender)+' (2023)';
end;

function TAboutForm.GetVersion(Sender: TObject):String;
// [0] = Major version, [1] = Minor ver, [2] = Revision, [3] = Build Number
// The above values can be found in the menu: Project > Project Options > Version Info
Var Majver, Minver, BuildNum:string;
    Info: TVersionInfo;
begin
 Info := TVersionInfo.Create;
 Info.Load(HINSTANCE);
 BuildNum := IntToStr(Info.FixedInfo.FileVersion[3]);
 Majver := IntToStr(Info.FixedInfo.FileVersion[0]);
 Minver:=IntToStr(Info.FixedInfo.FileVersion[1]);
 Info.Free;
 Result:=Majver+'.'+Minver+'.'+BuildNum
end;

procedure TAboutForm.Panel2Click(Sender: TObject);
begin
   OpenDocument('https://sourceforge.net/projects/caissystem/files/MV2_Studio_for_Windows%28Lazarus_project%29/');
end;

end.

