unit Unit1;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, ExtCtrls, LazFileUtils,
  Buttons, StdCtrls, IniFiles, windows, lazutf8;

type

  //Запись в Pravila.ini
  TRecordPravilo = record
    StarterRoot: string[200];
    StarterGroupMask: string[25];
    StarterPrefixMask: string[25];
    FSRoot: string[250];
    FSSubdirMask: string[25];
    FSPrefixNameMask: string[25];
    FSSubdirList: string;
  end;

  { TForm1 }

  TForm1 = class(TForm)
    BitBtn1: TBitBtn;
    BitBtn2: TBitBtn;
    CaptionBase: TLabeledEdit;
    Pravilo: TComboBox;
    Label1: TLabel;
    SpeedButton1: TSpeedButton;
    PraviloEdit: TSpeedButton;
    Suffix: TLabeledEdit;
    procedure BitBtn1Click(Sender: TObject);
    procedure BitBtn2Click(Sender: TObject);
    procedure CaptionBaseKeyPress(Sender: TObject; var Key: char);
    procedure FormCreate(Sender: TObject);
    procedure PraviloEditClick(Sender: TObject);
    procedure PraviloKeyPress(Sender: TObject; var Key: char);
    procedure PraviloKeyUp(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure SpeedButton1Click(Sender: TObject);
    procedure SuffixKeyPress(Sender: TObject; var Key: char);
    procedure SuffixKeyUp(Sender: TObject; var Key: Word; Shift: TShiftState);
  private
    { private declarations }
  public
    { public declarations }
  end;

const
  PravilaIni = 'Pravila.ini';
  SuffixSection = '_Суффиксы_';

var
  Form1: TForm1;

  FP: string;
  FIni: TIniFile;

procedure ShowError(Text:string);

function ListPravila:TStringList;
function GetPravilo(Name:string):TRecordPravilo;

function GetUID:string;
function StrToStringList(Text:string;Delimiter:string):TStringList;
function StringListToStr(SL:TStrings;Delimiter:string):string;

implementation

{$R *.lfm}

uses Unit2, Unit3;

procedure ShowError(Text:string);
begin
  showmessage(Text);
end;

//Возвращает список доступных правил
function ListPravila:TStringList;
var sl: TStringList;
  	i: integer;
begin
  sl:=TStringList.Create;
  FIni := TIniFile.Create(FP+PravilaIni);
  FIni.ReadSections(sl);
  FIni.Free;
  if sl.Count>0 then
    for i:=0 to sl.Count-1 do
      if sl[i]=SuffixSection then begin
        sl.Delete(i);
        Break;
      end;
  ListPravila :=sl;
end;

//Получить данные правила по имени
function GetPravilo(Name:string):TRecordPravilo;
var pr: TRecordPravilo;
begin
  FIni := TIniFile.Create(FP+PravilaIni);

  pr.StarterRoot 				:= FIni.ReadString(Name,'StarterRoot','');
  pr.StarterGroupMask 	:= FIni.ReadString(Name,'StarterGroupMask','');
  pr.StarterPrefixMask 	:= FIni.ReadString(Name,'StarterPrefixMask','');
  pr.FSRoot 						:= FIni.ReadString(Name,'FSRoot','');
  pr.FSSubdirMask 			:= FIni.ReadString(Name,'FSSubdirMask','');
  pr.FSPrefixNameMask 	:= FIni.ReadString(Name,'FSPrefixNameMask','');
  pr.FSSubdirList 			:= FIni.ReadString(Name,'FSSubdirList','');

  FIni.Free;
  GetPravilo:=pr;
end;

//Сформировать псевдо уникальный идентификатор
//в формате типа: "a6db3dd8-817f-400d-9c3c-a006bff533b0"
function GetUID:string;
const A: array [0..15] of string[1] = ('0','1','2','3','4','5','6','7','8','9','a','b','c','d','e','f');
var i: byte;
    s: string;
begin

  s:='';
  for i:=1 to 36 do begin
    if (i=9) or (i=14) or (i=19) or (i=24) then begin
      s:=s+'-'; continue;
    end;
    s:=s+A[random(16)];
  end;

  GetUID:=s;

end;

function StrToStringList(Text:string;Delimiter:string):TStringList;
var sl: TStringList;
begin
	sl:=TStringList.Create;

  sl.Text:= StringReplace(Text,Delimiter,chr(13)+chr(10),[rfReplaceAll]);

  StrToStringList:=sl;
end;

function StringListToStr(SL:TStrings;Delimiter:string):string;
var s: string;
    i: integer;
begin
  s:='';
  if SL.Count>0 then
    for i:=0 to SL.Count-1 do begin
      s:=s+SL[i];
      if i<SL.Count-1 then s:=s+',';
    end;
  StringListToStr:=s;
end;

{ TForm1 }

procedure TForm1.BitBtn2Click(Sender: TObject);
begin
  Close;
end;

procedure TForm1.CaptionBaseKeyPress(Sender: TObject; var Key: char);
begin
  if key = chr(13) then Suffix.SetFocus;
end;

procedure TForm1.BitBtn1Click(Sender: TObject);
var pr: TRecordPravilo;
  	s,SR, RD, BaseName, BasePath, BaseNameStarter: string;
    list: TStringList;
    Ini: TIniFile;
    i: integer;
begin

  //Проверки корректности полей
  if CaptionBase.Text = '' then begin
     ShowError('Не указано наименование базы!'); exit;
  end;

  pr:=GetPravilo(Pravilo.Text);
  s:=GetEnvironmentVariableUTF8('APPDATA')+'\1C\1CEStart\ibases.v8i';

  //Открываем ibases.v8i
  Ini:=TIniFile.Create(s);

  //Проверки:

  //SR:=pr.StarterRoot;
  //if not Ini.SectionExists(SR) then begin
  //  ShowError('Корневой секции не существует!'); exit;
  //end;

  RD:=pr.FSRoot;
  if not DirectoryExistsUTF8(RD) then begin
    ShowError('Корневой каталог для базы не существует!'); Exit;
  end;

  //Создаем каталог для базы: ---------------------------------------------------------

  //Нужно создавать подкаталог по маске?
  if pr.FSSubdirMask<>'' then begin
    RD:=RD+FormatDateTime(pr.FSSubdirMask,Now)+'\';
    //Подкаталог по маске уже существует?
    if not DirectoryExistsUTF8(RD) then begin
      ForceDirectoriesUTF8(RD);
    end;
  end;

  BaseName:=CaptionBase.Text; BaseNameStarter:=BaseName;
  //Формируем префикс названия базы для каталога
  if pr.FSPrefixNameMask<>'' then begin
  	BaseName:=FormatDateTime(pr.FSPrefixNameMask,Now)+' '+BaseName;
  end;
  //Формируем префикс названия базы для стартера
  if pr.StarterPrefixMask<>'' then begin
    BaseNameStarter:=FormatDateTime(pr.StarterPrefixMask,Now)+' '+BaseNameStarter;
  end;
  //Формируем суффикс названия базы для каталога и стартера
  if Suffix.Text<>'' then begin
  	BaseName:=BaseName+' '+Suffix.Text;
    BaseNameStarter:=BaseNameStarter+' '+Suffix.Text;
  end;

  //Создаем каталог базы
  BasePath:=RD+BaseName;
  ForceDirectoriesUTF8(BasePath);

  //Создаем доп подкаталоги в каталоге базы
  if pr.FSSubdirList<>'' then begin
    list:=StrToStringList(pr.FSSubdirList,',');
    for i:=0 to list.count-1 do begin
      ForceDirectoriesUTF8(BasePath+'\'+list[i]);
    end;
  end;

  //Создаем запись в стартере: --------------------------------------------------------

  //Нужно ли создавать подгруппу по маске?
  if pr.StarterGroupMask<>'' then begin
    SR:=FormatDateTime(pr.StarterGroupMask,Now);
    //Подгруппа уже существует?
    if not Ini.SectionExists(SR) then begin
      //Создаем подгруппу
      Ini.WriteString(SR,'ID',GetUID); //Из функции-генератора уникального идентификатора
      Ini.WriteInteger(SR,'OrderInList',-1);
      Ini.WriteString(SR,'Folder',Ini.ReadString(pr.StarterRoot,'Folder','')+'/'+pr.StarterRoot); //Брать из корневой папки + "/имя корневой"
      Ini.WriteInteger(SR,'OrderInTree',-1);
      Ini.WriteInteger(SR,'External',0);
    end;
  end
  else
  begin
       SR:=pr.StarterRoot;
  end;

  //Создаем запись
  Ini.WriteString(BaseNameStarter,'Connect','File="'+BasePath+'";');
  Ini.WriteString(BaseNameStarter,'ID',GetUID);
  Ini.WriteInteger(BaseNameStarter,'OrderInList',-1);
  Ini.WriteString(BaseNameStarter,'Folder',Ini.ReadString(SR,'Folder','')+'/'+SR); //?????
  Ini.WriteInteger(BaseNameStarter,'OrderInTree',-1);
  Ini.WriteInteger(BaseNameStarter,'External',0);
  Ini.WriteString(BaseNameStarter,'ClientConnectionSpeed','Normal');
  Ini.WriteString(BaseNameStarter,'App','Auto');
  Ini.WriteString(BaseNameStarter,'WA','1');
  Ini.WriteString(BaseNameStarter,'Version','8.3');

	Ini.Free;

  Close;

end;

procedure TForm1.FormCreate(Sender: TObject);
var
    sl: TStringList;
begin
  Randomize;
  FP:=ExtractFilePath(ParamStr(0));
  sl:=ListPravila;
  Pravilo.Items.AddStrings(sl);
  if sl.Count>0 then Pravilo.Text:=sl[0];
end;

procedure TForm1.PraviloEditClick(Sender: TObject);
begin
  if Form3.ShowModal=mrOK then begin

    //Перезагрузить список правил

  end;
end;

procedure TForm1.PraviloKeyPress(Sender: TObject; var Key: char);
begin
  if key = chr(13) then BitBtn1Click(nil);
end;

procedure TForm1.PraviloKeyUp(Sender: TObject; var Key: Word; Shift: TShiftState
  );
begin
  if Key = VK_F2 then begin
     PraviloEditClick(nil);
  end;
end;

procedure TForm1.SpeedButton1Click(Sender: TObject);
begin
  if Form2.ShowModal=mrOK then begin
    Suffix.Text:=Form2.LB.Items[Form2.LB.ItemIndex];
  end;
end;

procedure TForm1.SuffixKeyPress(Sender: TObject; var Key: char);
begin
  if key = chr(13) then Pravilo.SetFocus;
end;

procedure TForm1.SuffixKeyUp(Sender: TObject; var Key: Word; Shift: TShiftState
  );
begin
  if Key = VK_F4 then begin
    SpeedButton1Click(nil);
  end;
end;

end.

