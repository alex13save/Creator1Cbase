unit Unit2;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, StdCtrls,
  Buttons, Unit1, IniFiles, LCLtype;

type

  { TForm2 }

  TForm2 = class(TForm)
    BitBtn1: TBitBtn;
    BitBtn2: TBitBtn;
    Edit1: TEdit;
    LB: TListBox;
    SB_Add: TSpeedButton;
    SB_Refresh: TSpeedButton;
    SP_Delete: TSpeedButton;
    procedure FormCreate(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure LBClick(Sender: TObject);
    procedure LBDblClick(Sender: TObject);
    procedure SB_AddClick(Sender: TObject);
    procedure SB_RefreshClick(Sender: TObject);
    procedure SP_DeleteClick(Sender: TObject);
  private
    { private declarations }
    procedure SaveSuffixes;
  public
    { public declarations }
  end;

var
  Form2: TForm2;

implementation

{$R *.lfm}

{ TForm2 }

procedure TForm2.FormCreate(Sender: TObject);
var FIni: TIniFile;
  	s: string;
begin
  FIni:=TIniFile.Create(FP+PravilaIni);
  s:=FIni.ReadString(SuffixSection,'List','');
  if s<>'' then begin
    LB.Items.AddStrings(StrToStringList(s,','));
  end;
  FIni.Free;
end;

procedure TForm2.SaveSuffixes;
var FIni: TIniFile;
  	s: string;
begin
  FIni:=TIniFile.Create(FP+PravilaIni);
  s:=StringListToStr(LB.Items,',');
  FIni.WriteString(SuffixSection,'List',s);
  FIni.Free;
end;

procedure TForm2.FormShow(Sender: TObject);
begin
  LB.SetFocus;
  if LB.Items.Count>0 then LB.Selected[0]:=true;
end;

procedure TForm2.LBClick(Sender: TObject);
begin
  Edit1.Text:=LB.GetSelectedText;
end;

procedure TForm2.LBDblClick(Sender: TObject);
begin
  BitBtn1.Click;
end;

procedure TForm2.SB_AddClick(Sender: TObject);
begin
  if LB.Items.IndexOf(Edit1.Text)>=0 then begin
    Application.MessageBox('Элемент уже есть в списке!', 'Внимание!', MB_ICONERROR+MB_OK);
  end;
  LB.Items.Add(Edit1.Text);
  SaveSuffixes;
end;

procedure TForm2.SB_RefreshClick(Sender: TObject);
begin
  if LB.ItemIndex>=0 then begin
    LB.Items[LB.ItemIndex]:=Edit1.Text;
    SaveSuffixes;
  end;
end;

procedure TForm2.SP_DeleteClick(Sender: TObject);
begin
  if LB.ItemIndex>=0 then
    if Application.MessageBox('Элемент будут удален! Продолжать?','Внимание!',MB_ICONQUESTION+MB_YESNO) = IDYES then begin
      LB.Items.Delete(LB.ItemIndex);
      SaveSuffixes;
    end;
end;


end.

