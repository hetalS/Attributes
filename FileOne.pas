
unit delstgdlg;

{20001128,rtr: Make selected grid half the width of Available/choices list.
   Set list grid column header label font to bold for consistency.
   Ref TD# 379.
 20001128,rtr: Fixed Ok/Cancel button font to bold. Ref TD# 380.
 20001128,rtr: Fixed positioning of list picker dialog.  Ref TD# 378.
 20010626,cmh: added multi select handling td#1703
 20010809,cmh: Fix TD #1971 - Grid repositioning on select
 20020806,jdh; Added support for Touchscreen. Enh# 674
 20021113,gns: Added Ref Handling so values may contain special characters. Ref Enh# 532.
 20030627,cmh: Fixed current item being first one moved to list. Ref TD# 5044
 20030627,cmh: Fixed scrolling of available item list. Ref TD# 5045
 20030710,rtr: Changes related to Enh# 757.
 20031103,rtr: Fixed Repeating error messages when using ALL in list builder containing values
   which exceed 4k. Ref TD# 5662.
 20031125,rtr: Fixed Long wait time when selecting items from the List Builder Dialog. Ref TD# 5774.
 20040218,cmh: Added set of MaxLength to prevent truncation of values. Ref. TD# 6082
 20040325,gns: Replaced selected record handling with faster method. Ref. TD #6195.
 20040527,cmh: Fixed incorrect behavior of selection of list grids. Ref. TD# 6357, 6400
 20040802,rtr: Commented out unused function PrepErrorMsg().
 20040922,ht : Remove warnings and comment out usused functions
 20041027,cmh: Fixed incorrect multiple record settings. Ref. TD #6904
 20050906,ht : Remove condition of required compiler directives.
}
{Sample change}
{Sample second line}
{sample third line}



interface

uses
  SysUtils, WinTypes, WinProcs, Messages, Classes, Graphics, Controls,
  Forms, Dialogs, sfDlgs, StdCtrls, ExtCtrls
  , sfglobal
  , fwconst
  , SfForms
  , Buttons, Grids
  , DelXtra
  , ListGrid
  , DBAccess
  , DBLook
  , db
  , StrCache
  , dbQryPls
  , fwVars
  , sfdbcmmn { gns 21-Dec-98 renamed dbcommon }
  , FwStrngs {gns 02-Apr-1999 }
  , madStrings
  ,fwClasses, SfButton, sfspeed
  ,UdvNav
  ,NavPlus, AdvGlowButton
  ,StdTools
  ,PopupKbd
  ;

type
  TSetNewItemCount = procedure (Cnt: Integer) of object;

  TDBPickerGrid = class(TDBLookupGrid)
  private
    procedure DoubleClick(Sender: TObject);
  public
  published
     property OnDblClick;
  end;

  tDelimitedStringDialog = class(TSfDialog)
    DoBtn: TSfButton;
    CancelBtn: TSfButton;
    OKBtn: TSfButton;
    CachePanel: TPanel;
    NavPanel: TPanel;
    ButtonAdd: TSfButton;
    ButtonRemove: TSfButton;
    ButtonAll: TSfButton;
    ButtonClear: TSfButton;
    NoteBook1: tNotebook;
    MsgMemo: TMemo;
    Label1: TLabel;
    Label2: TLabel;
    GridPanel: TPanel;
    SelectionLabel: TLabel;
    Label4: TLabel;
    ButtonSome: TSfButton;
    ButtonsPanel: TPanel;
    ButtonNew: TsfButton;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    {procedure ParentNavigatorClick(Sender: TObject;
      Button: TNavigateBtnPlus; var Handled: Boolean);}
    procedure DoBtnClick(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure ButtonAllClick(Sender: TObject);
    procedure ButtonClearClick(Sender: TObject);
    procedure ButtonAddClick(Sender: TObject);
    procedure ButtonRemoveClick(Sender: TObject);
    procedure FormResize(Sender: TObject);
    procedure CancelBtnClick(Sender: TObject);
    procedure ButtonSomeClick(Sender: TObject);
    procedure ButtonNewClick(Sender: TObject);
    procedure CancelBtnMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
  private
    { Private declarations }
    sfUDVNavigator : TsfUDVNavigator;
    SelectedList: tSFInputListGrid;
    LookupGrid: TDBPickerGrid;
    FSQLTransactionType: string;
    fTargetField: string;
    FTargetFieldsList: TfwStringList;

    fLookupSqlSource: tSFSqlSource;
    function GetLookupSQLSource: tSFSqlSource;
    procedure SetLookupSQLSource(value: tSFSqlSource);
    procedure DoLookup;
    procedure SetTargetField(value:String);
    procedure UpdateCountSelected;
    function GetRowValue: string;
    procedure AddNew(NewValue: string; var S: string);
    procedure AddValueToList;
    procedure MoveMany(aLimit: Integer = -1);
    procedure NavigatorClick(Sender: TObject; Button: TNavigateBtnPlus;
      var Handled: Boolean);
  protected
  public
    { Public declarations }
    LeftMargin, RightMargin, TopMargin, BottomMargin: integer;
//    procedure PopulateGridHeader;
  published
    property LookupSQLSource: tSFSqlSource read GetLookupSQLSource write SetLookupSQLSource;
    property TargetField: string read fTargetField write SetTargetField;
  end;

function FoundInDelimStr(const Value, Str, Delim: String): Boolean;
function ShowDelimitedStringDialog(aController: TWinControl;
  aSqlSource: tSFSqlSource;
  Values, ShowAsValues: TStrings;
  DelimStr: String;
  aTargetField: string;
  aDisplayFieldName: string;
  NewItemCount: TSetNewItemCount;
  ParseAvailableItems,
  AllowDuplicates,
  ShowNew: boolean): boolean;

implementation

{$R *.DFM}

resourcestring
sMoveItems = 'Move Items';
sNumToMove = 'Number of items to move:';
sSelectionItems = 'Selection (%d items selected)';


function ShowDelimitedStringDialog(aController: TWinControl;
  aSqlSource: tSFSqlSource;
  Values, ShowAsValues: TStrings;
  DelimStr: String;
  aTargetField: string;
  aDisplayFieldName: string;
  NewItemCount: TSetNewItemCount;
  ParseAvailableItems,
  AllowDuplicates,
  ShowNew: boolean): boolean;
var
  aDelimitedStringDialog: tDelimitedStringDialog;
  DlgResult : TModalResult;
begin
  result := false;
  aDelimitedStringDialog :=  tdelimitedstringdialog.create(aController);
  try
    with aDelimitedStringDialog do {rtr 11-28-00 Fixed positioning of list picker dialog.  Ref TD# 378.}
      begin
        Notebook1.pageindex := 0;
        if aController Is tSFInputListGrid then
          begin
            SelectedList.VerifyValue := tSFInputListGrid(aController).VerifyValue;
            SelectedList.ValidExpr := tSFInputListGrid(aController).ValidExpr;
            SelectedList.Caption := tSFInputListGrid(aController).Caption;
          end;
        SelectedList.Delimiter := DelimStr;
        SelectedList.DisplayFieldName := aDisplayFieldName;
        SelectedList.ParseAvailableItems := ParseAvailableItems;
        SelectedList.AllowDuplicates := AllowDuplicates;
        //SelectedList.ShowNew := ShowNew;
        LookupSQLSource := aSQLSource;
        DoLookup;
        SelectedList.RowCount := Values.Count;
        if assigned(ShowAsValues) then
          begin
            if ShowAsValues.Count <> Values.Count
              then raise Exception.Create('Return values count must be equal to ShowAs values count.');
            SelectedList.Cols[0].Assign(ShowAsValues);
          end
         else SelectedList.Cols[0].Assign(Values);
        SelectedList.Cols[1].Assign(Values);
        SelectedList.OriginalValues.Assign(Values);
        UpdateCountSelected;
        TargetField := aTargetField;
        SelectedList.LookupField := aTargetField;
        SelectedList.EditFieldName := aTargetField;
        if not among(tSFInputListGrid(aController).ReturnFields,['',aTargetField]) then
          begin
            SelectedList.AllowTyping := false;
            ShowNew := false;
          end;
        ButtonNew.Visible := ShowNew;

        Position := poDesigned;

        { place the window above or below the calling control}
        Left := aController.ClientOrigin.x;
        if (aController.ClientOrigin.Y
            +aController.ClientRect.Bottom + Height > Screen.Height) then
          Top := aController.ClientOrigin.y - Height
        else
          Top := aController.ClientOrigin.y+aController.ClientRect.Bottom;
        if Left+Width > Screen.Width then
          Left := Screen.Width - Width;
        //If only one value in available list and selected list is empty, add that one value by default
        //JIRA WIN-79
        if (SelectedList.RowCount = 1)   and (LookupSQLSource.DataSource.DataSet.RecordCount = 1) then
        begin
            LookupGrid.DoubleClick(nil);
            UpdateCountSelected;
        end;
        DlgResult := showmodal;
        if DlgResult = mrOK then
          begin
            if assigned(NewItemCount)
              then NewItemCount(SelectedList.RowCount);
            Values.Assign(SelectedList.Cols[1]);
            ShowAsValues.Assign(SelectedList.Cols[0]);
            result := true;
          end;
      end;
  finally
    aDelimitedStringDialog.Free;   { PLR 6/2/99 }
  end;
end;

procedure tDBPickerGrid.DoubleClick(Sender: tObject);
begin
  with tDelimitedStringDialog(owner.owner) do
    begin
      AddValueToList;
      UpdateCountSelected;
    end;
end;

procedure tDelimitedStringDialog.FormCreate(Sender: TObject);
var
  NB: TNavigateBtnPlus;
begin
  ApplyGlobalFontDef(Font);

  LeftMargin := 0;
  RightMargin := 0;
  TopMargin := 0;
  BottomMargin := 0;
  CachePanel.Visible := true; {cmh 19990601}
  FSQLTransactionType := sUpdate; {rtr 10-21-99}
  FTargetField := '';
  FTargetFieldsList := TfwStringList.create;

  SelectedList :=  tSFInputListGrid.create(cachepanel);
  SelectedList.parent := cachepanel;
  selectedList.SetBounds(0,0,150,150);
  SelectedList.align := alLeft;
  selectedList.visible := true;
  SelectedList.ReadOnly := false;
  SelectedList.Color := clWhite;
  LookupGrid := TDBPickerGrid.Create(GridPanel);
  LookupGrid.OnDblClick := LookupGrid.DoubleClick;
  Lookupgrid.align := alClient;
  {rtr 11-28-00 Set list grid column header label font to bold for consistency}
  LookupGrid.TitleFont.Name  := GlobalFontName;
  LookupGrid.TitleFont.Style := GlobalFontStyle;
  LookupGrid.TitleFont.Size := 8;
  if EnableBigButtons then
    begin
      self.Height := Trunc (self.Height * AdjustmentFactor);
      ButtonAdd.Height := Trunc (ButtonAdd.Height * AdjustmentFactor);
      ButtonRemove.Top := ButtonAdd.TOp + ButtonAdd.Height + 4;
      ButtonRemove.Height := Trunc (ButtonRemove.Height * AdjustmentFactor);
      ButtonSome.Height := Trunc (ButtonSome.Height * AdjustmentFactor);
      ButtonSome.Top := ButtonRemove.Top + ButtonRemove.Height + 4;
      ButtonAll.Height := Trunc (ButtonAll.Height * AdjustmentFactor);
      ButtonAll.Top := ButtonSome.Top + ButtonSome.Height + 4;
      ButtonClear.Height := Trunc (ButtonClear.Height * AdjustmentFactor);
      ButtonClear.Top := ButtonAll.Top + ButtonAll.height + 4;
      ButtonNew.Height := Trunc (ButtonNew.Height * AdjustmentFactor);
      ButtonNew.Top := ButtonClear.Top + ButtonClear.height + 4;
      DoBtn.Height := Trunc (DoBtn.Height * AdjustmentFactor);
      CancelBtn.Height := Trunc (CancelBtn.Height * AdjustmentFactor);
    end;

  sfUDVNavigator := TsfUDVNavigator.Create(Self);
  with sfUDVNavigator do
    begin
      Parent := ButtonsPanel;
      sfUDVNavigator.Align := alBottom;
      Ctl3D := False;
      for NB := Low(Buttons) to High(Buttons) do
        Buttons[NB].Visible := False;
      Buttons[nbFirst].Visible := False;
      Buttons[nbPrior].Visible := False;
      Buttons[nbNext].Visible := False;
      Buttons[nbLast].Visible := False;
      buttons[nbMark].Visible := True;
      buttons[nbGoto].Visible := True;
      buttons[nbFilter].Visible := True; {20040318,rtr: Added filter to Simple Tabular Reports Tool Window. Ref Enh# 814.}
      buttons[nbReport].Visible := False;
      buttons[nbRefresh].Visible := True;
      SetBounds(1, 1, 4*27, 20); {20041202,rtr: Cosmetic changes}
      ButtonsPanel.width := sfUDVNavigator.width + 1;   { JDH 3/28/2001 TD#722 This makes the DescPanel wider giving more room for larger titles}
//      OnClick := DBNavigatorPlus1Click;
      sfUDVNavigator.OnClick := NavigatorClick;
    end;
end;

procedure tDelimitedStringDialog.NavigatorClick(Sender: TObject; Button: TNavigateBtnPlus;
  var Handled: Boolean);
begin
  case Button of
    nbRefresh:
      if assigned(fLookupSqlSource) then 
      begin
        fLookupSqlSource.Refresh;
        LookupGrid.LayOutChanged;
        Handled := True;
      end;
  end;
end;

procedure tDelimitedStringDialog.SetTargetField(value: String);
begin
  fTargetField := trim(value);
  ParseStrToStringList(fTargetField,[','],FTargetFieldsList,true);
end;

procedure tDelimitedStringDialog.FormDestroy(Sender: TObject);
begin
  FTargetFieldsList.Free;
end;

(*procedure tDelimitedStringDialog.PopulateGridHeader;
var
  theField: TField;
begin
//  theField:= (LookupSQLSource.DataSource.DataSet).fieldbyName(FTargetField);    //added set of MaxLength to existing stub method. Ref. TD# 6082
//  SelectedList.MaxLength := theField.Size;                                      //added set of MaxLength to existing stub method. Ref. TD# 6082
end; *)

procedure tDelimitedStringDialog.DoBtnClick(Sender: TObject);
begin
  ModalResult := mrOK;
end;

procedure tDelimitedStringDialog.FormShow(Sender: TObject);
begin
  GridPanel.parent := CachePanel;
  LookupGrid.parent := GridPanel;
  GridPanel.Visible := true;
  LookupGrid.visible := true;
  lookupgrid.Enabled := true;
//  PopulateGridHeader;
  SelectedList.ShowDlgButton := false;
end;

function tDelimitedStringDialog.GetLookupSQLSource: tSFSqlSource;
begin
  result := fLookupSQLSource;
end;

procedure tDelimitedStringDialog.SetLookupSQLSource(value: tSFSqlSource);
begin
  fLookupSQLSource := value;
  if assigned(Value)
    then sfUDVNavigator.DataSource := fLookupSqlSource.DataSource
    else sfUDVNavigator.DataSource := nil;
end;

procedure tDelimitedStringDialog.DoLookup;
begin
  Lookupgrid.DataSource := fLookupSqlSource.DataSource;
  Lookupgrid.DataSource.Enabled := true;
end;

function FoundInDelimStr(const Value, Str, Delim: String): Boolean;
begin
  result := (PosStr(Delim+Value+Delim,Str) > 0) or StartsWith(Str,Value+Delim,false);
end;

function tDelimitedStringDialog.GetRowValue: string;
var
  j: Integer;
  Delim: string;
begin
  result := '';
  for j := 0 to FTargetFieldsList.Count-1 do
    begin
      if J+2 <= length(SelectedList.Delimiter)
        then Delim := SelectedList.Delimiter[j+2];
      with LookupSQLSource.DataSource.DataSet do
        if result = ''
          then result := FieldByName(FTargetFieldsList[j]).AsString
          else Cat(result, Delim+FieldByName(FTargetFieldsList[j]).AsString);
    end;
  result := RefToStr(result);
end;

procedure tDelimitedStringDialog.UpdateCountSelected;
var
  Cnt, I: Integer;
begin
  Cnt := SelectedList.RowCount;
  for I := SelectedList.RowCount-1 downto 0 do
     if SelectedList.Cells[0,I] = ''
       then Dec(Cnt)
       else break;
  SelectionLabel.Caption := Format(sSelectionItems,[BoolToInteger(SelectedList.TextValue=sEmpty,0,Cnt)]);
end;

procedure tDelimitedStringDialog.AddNew(NewValue: string; var S: string);

  procedure AddIt(const Value: string);
  var
   DispValue: string;
  begin
    if SelectedList.AllowDuplicates
       or not FoundInDelimStr(Value,S,SelectedList.Delimiter[1]) then
      begin
        Cat(S,Value+SelectedList.Delimiter[1]);
        if SelectedList.DisplayFieldName <> ''  then
           DispValue := LookupSQLSource.DataSource.DataSet.FieldByName(SelectedList.DisplayFieldName).AsString
          else DispValue := Value;

        SelectedList.AddToList(DispValue,Value);
        LookupGrid.AddToExcludeFromPaintList(DispValue);       //Hetal
      end;
  end;

var
  TokenCount: Integer;
  I: integer;
begin
  if SelectedList.ParseAvailableItems then
    begin
      TokenCount := NumberOf(SelectedList.Delimiter[1],NewValue)+1;
      if (SelectedList.DisplayFieldName <> '') and (TokenCount <> NumberOf(SelectedList.Delimiter[1],SelectedList.DisplayFieldName)+1)
        then raise Exception.Create(format('Unequal number of tokens between %s and %s',[NewValue,SelectedList.DisplayFieldName]));
      for I := 1 to TokenCount do
        AddIt(GetToken(NewValue,I,SelectedList.Delimiter[1]));
    end
   else AddIt(NewValue);
end;

procedure tDelimitedStringDialog.AddValueToList;
var
  S: string;
begin
  S := SelectedList.TextValue;
  if S <> ''
    then Cat(S,SelectedList.Delimiter[1]);
  AddNew(GetRowValue,S);
end;

procedure tDelimitedStringDialog.MoveMany(aLimit: Integer = -1);
var
  PriorPosition: TBookMarkStr;              {20010809,cmh: Fix TD #1971 - Grid repositioning on select}
  S: String;
  aCount: Integer;
begin
 if assigned(LookupSQLSource) then
 if assigned(LookupSQLSource.DataSource) then
   begin
     {20031125,rtr: Refactoring / cosmetic}
     Screen.Cursor := crHourglass;
     LookupGrid.BeginUpdate;           // 20030627,cmh: Ref TD# 5044, 5045
     try
       with LookupSQLSource.DataSource.DataSet do
         begin
           PriorPosition := Bookmark;        {20010809,cmh: Fix TD #1971 - Grid repositioning on select}
           S := SelectedList.TextValue;
           if S <> ''
             then Cat(S,SelectedList.Delimiter[1]);
           if aLimit = -1
             then first;
           aCount := 0;
           if SelectedList.AllowDuplicates then
             begin
               for aCount := 1 to aLimit do
                 AddNew(GetRowValue,S);
             end
            else
             while not eof do
             begin
               AddNew(GetRowValue,S);
               Inc(aCount);
               if (aLimit > -1) and (aCount = aLimit)
                 then Break;
               next;
             end;
             Bookmark := PriorPosition;      {20010809,cmh: Fix TD #1971 - Grid repositioning on select}
         end;
     finally
       LookupGrid.EndUpdate;  // 20030627,cmh: Ref TD# 5044, 5045
       UpdateCountSelected;
       LookupGrid.Repaint;    // 20030627,cmh: Ref TD# 5044, 5045
       Screen.Cursor := crDefault;
     end;
   end;
end;

procedure tDelimitedStringDialog.ButtonAddClick(Sender: TObject);
var
  S: String;
  PriorPosition: TBookMarkStr;              {20010809,cmh: Fix TD #1971 - Grid repositioning on select}
begin
  if assigned(LookupSQLSource) then
    if not TSFQuery(LookupSQLSource.datasource.Dataset).HasSelected then // 20030627,cmh: Ref TD# 5044, 5045
      begin     //  20040527,cmh:  Ref. TD# 6357, 6400
        LookupGrid.DoubleClick(nil);
        UpdateCountSelected;
        exit;   //  20040527,cmh:  Ref. TD# 6357, 6400
      end;
  if Not (assigned(LookupSQLSource) and assigned(LookupSQLSource.DataSource))
    then Exit;
  Screen.Cursor := crHourglass;
  LookupGrid.BeginUpdate;
  try
    with TSfQuery(LookupSQLSource.DataSource.DataSet) do
      begin
        {20031125,rtr: Fixed Long wait time when selecting items from the List Builder Dialog. Ref TD# 5774.}
        PriorPosition := Bookmark;        {20010809,cmh: Fix TD #1971 - Grid repositioning on select}
        S := SelectedList.TextValue;
        if S <> ''
          then Cat(S,SelectedList.Delimiter[1]);
        FirstSelected;
        while not EOFSelected do
          begin
            AddNew(GetRowValue,S);
            NextSelected;
          end;
          Bookmark := PriorPosition;      {20010809,cmh: Fix TD #1971 - Grid repositioning on select}
      end;
  finally
    LookupGrid.EndUpdate;
    UpdateCountSelected;
    LookupGrid.Repaint;
    Screen.Cursor := crDefault;
  end;
end;

procedure tDelimitedStringDialog.ButtonClearClick(Sender: TObject);
begin
  LookupGrid.ClearExcludeFromPaintList;  //Hetal
  SelectedList.ClearValues;
  SelectedList.TextValue := sEmpty; {20030710,rtr: Changes related to Enh# 757.}
  UpdateCountSelected;
end;

procedure tDelimitedStringDialog.ButtonAllClick(Sender: TObject);
begin
  MoveMany(-1);
end;

procedure tDelimitedStringDialog.ButtonRemoveClick(Sender: TObject);
var
  RowDispText: string;
begin
  RowDispText :=  SelectedList.GetRowDisplayText(SelectedList.Row);  //Hetal
  LookupGrid.RemoveFromExcludeFromPaintList(RowDispText);
  
  SelectedList.DeleteRow(SelectedList.Row);
  UpdateCountSelected;
end;

procedure tDelimitedStringDialog.FormResize(Sender: TObject);
begin
 ButtonAll.Left := (Width div 3 {rtr 11-28-00 Was 2.  Make selected grid half the width of Available/choices list}) - (ButtonAll.Width div 2);
 ButtonSome.Left := ButtonAll.Left;
 ButtonClear.Left := ButtonAll.Left;
 ButtonNew.Left := ButtonAll.Left;
 ButtonAdd.Left := ButtonAll.Left;
 ButtonRemove.Left := ButtonAll.Left;
 SelectedList.width := ButtonAll.Left - 20; {rtr 11-28-00 Was "- 30" Improve symmetry}
 SelectedList.Left := 10;
 GridPanel.left := ButtonAll.Left + ButtonAll.Width + 30;
 GridPanel.width := width - (ButtonAll.Left + ButtonAll.Width) - 30;
 SelectionLabel.left := SelectedList.Left+ 5;
 Label4.left := GridPanel.left + 5;
end;

procedure tDelimitedStringDialog.CancelBtnClick(Sender: TObject);
begin
  ModalResult := mrCancel;
end;

procedure tDelimitedStringDialog.ButtonSomeClick(Sender: TObject);
var
  Value: String;
  I: Integer;
begin
  if EnablePopUpKeyboard    { hide popup keyboard - plr 1/27/03 }
    then HidePopupKeyboard;
  Value := '';
  if SfInputQuery(sMoveItems, sNumToMove, Value) then
    begin
      I := StrToIntDef(Value,-1);
      if I < 1 then
        begin
          sfMessageDlg(sInvalidPositiveNumber,mtError,[mbOk],0);
          exit;
        end;
      MoveMany(I);
    end;
end;

procedure tDelimitedStringDialog.ButtonNewClick(Sender: TObject);
begin
  if EnablePopUpKeyboard    { hide popup keyboard - plr 1/27/03 }
    then HidePopupKeyboard;
  SelectedList.ShowFillWizard(TWinControl(owner));
  UpdateCountSelected;
end;

procedure tDelimitedStringDialog.CancelBtnMouseDown(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  CancelEdits;
end;

procedure tDelimitedStringDialog.FormClose(Sender: TObject;
  var Action: TCloseAction);
begin
  if fLookupSqlSource <> nil
    then fLookupSqlSource.Filter := '';
end;

end.

