unit ListGrid;

// Need to consolidate EditFieldName and LookupField, but not now... Too close to release!
//   When schedule permits, change LookupField references to EditFieldName!!
//Sample editing
interface
uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs
  ,DB
  , DbConsts
  , DbCtrls
  , SfVars
  , fwgrids
  , Mask
  , StdCtrls,ExtCtrls
  , buttons
  , strplus
  , fwstrngs
  , DelXtra
  , SfTranslate
  , dbEdtPls,
    sfDatasets, { GNS 10-13-99 }
    FwSql,
    FwSqlUtl,
    FwConst,
    FrmPlace,
    StdTools,
    Sf2kCmmn,
    DbCtrl,
    SfTools,
    SfIni,
    Diagnose,
    EwiConst,
    FwForms,
    FwErrors,
    SfForms,
    Sysmwin,
//    hotkeys  { plr 9/29/98 }
   dbaccess
   ,dbSFPls2
    ,DragMgr
    ,dbclrpls {20001122,cmh}
    ,Dbctlpls {ghl, 03/09/2001}
   ,PopupKbd
   ,ClipBrd
   ,DBLabelPls
  ,FwSqlCommon
  ,fwtypes
  ,KbdScan
  ,SfSpeed
  ,madStrings
  ,fwClasses
  ,SfDbCmmn
  ,FillWizard
  ,TxtScrlr
{$ifdef codesite}
  ,csintf
{$endif}
  ,StrgsDlg
  ,fwAppHooks
  ,dbgrdpls
;

type
{ ghl, 03/09/2001 ref ENH #544}
  // Note: this class (TTaborderCtrl) definition is here just so we can utilize
  // the protected properties and functions of Twin Control
  TTaborderTestCtrl = class(TwinControl);

  tSFListGrid = class(tStringGrid)
  private
    fHidden: boolean;
//    fField : tField;
    fModified: boolean;
//    fZeroAsNull: boolean;
//    fDataSource : tSFSQLSource;//}tDataSource;
    fLabel: tSFCaptionLabel;
    fMaxLength : integer;
    FEditFieldName: string;
    fReadOnly,
    FForceHideDlgButton: boolean;
    fDelim: string;
    FReturnFields: string;
    FDisplayFieldName: string;
    FParseAvailableItems: boolean;
    FAllowDuplicates: boolean;
    FShowNew: boolean;
    FGeneratorSqlId: string;
//    DlgButton: tSpeedButton; {rtr 11-28-00 Moved to public}
    fBtnControl: tWinControl;
//    fShowDlgButton: boolean;
//    FEditFieldName: String;  { plr 10/30/98 }
{//0801}    FLookupSqlSource : TsfSqlSource;
//    FCaption: String;
    FCaptionPos: tCaptionPos;
    LeftGap: integer;
    AboveGap: integer;
    FOriginalValues: TfwStringList;
    FDesigningState: TDesigningState;
    FOriginalCaption: string;
    procedure SetTextValue(value: string);
    function GetTextValue: string;
    procedure SetTextDisplay(value: string);
    function GetTextDisplay: string;
    procedure SetEditFieldName(Value: string);
    procedure SetReadOnly(value: boolean);
    function GetReadOnly : boolean;
    procedure SetMaxLength(value: integer);
    procedure SelectCellEvent(Sender: TObject; ACol, ARow: Longint; var CanSelect: Boolean);
    procedure SetEditTextEvent(Sender: TObject; ACol, ARow: Longint; const Value: string) ;
    procedure OnKeyUpEvent(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure UpdateRowCount;
    procedure UpdateCaption(Params: TStrings = nil); virtual; abstract;
    procedure SetUdvDesigning(Value: TDesigningState); virtual;
    function GetCaption: string;
    procedure SetCaption(value: string);
    procedure SetCaptionPos(value: tCaptionPos);
    function GetCaptionPos: TCaptionPos;
    procedure SetCaptionFont(value: tFont);
    function GetCaptionFont: tFont;
    procedure CMParentFontChanged(var Message: TMessage); message CM_PARENTFONTCHANGED;
//    procedure PositionCaption;
    function GetVisible: boolean;
    procedure SetVisible(const Value: boolean);
    function LoadComboGlyph: HBitmap;
    procedure CreateDlgButton; virtual;
    function GetDelimiter: string;
    procedure SetDelimiter(value: string);
    procedure SetReturnFields(value: string);
    procedure SetDisplayFieldName(value: string);
    procedure SetHidden(const Value: boolean);  {200000908 CMH}
    function  GetHidden : boolean;              {200000908 CMH}
  protected
    procedure SetParent(AParent : TWinControl); override;
    procedure Loaded; override; {rtr 1-25-01 Added}
    procedure SetShowDlgButton(value: boolean);
    function GetShowDlgButton: boolean;
    function DlgButtonRect: TRect;
  public
    DlgButton: tSfSpeedButton;
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure SetBounds(ALeft, ATop, AWidth, AHeight: Integer);override;
    function PasteAllowed(C: TControl): Boolean;
//    property EditFieldName:String read FEditFieldName write fEditFieldName; { plr 10/30/98 }
    procedure AddToList(c0, c1: string);
    procedure DeleteRow(ARow: integer);override;
    procedure ClearValues;
    procedure UpdateFromValue(value: string; HandleDisplayFieldName: boolean; IsOriginalValues: boolean = false);
    property TextValue: string read GetTextValue write SetTextValue;
    property TextDisplay: string read GetTextDisplay write SetTextDisplay;
    property Hidden : boolean read GetHidden write SetHidden; {20000908}
    property ForceHideDlgButton: boolean read FForceHideDlgButton write FForceHideDlgButton; {rtr 1-25-01 Added}
    property OriginalValues: TfwStringList read FOriginalValues;
    property SFCaption: TSFCaptionLabel read FLabel;
    function GetRowDisplayText(ARow: integer): string;
  published
    property ShowDlgButton : boolean read GetShowDlgButton write SetShowDlgButton;
    property Delimiter: string read GetDelimiter write SetDelimiter;
    property ReturnFields: string read FReturnFields write SetReturnFields;
    property DisplayFieldName: string read FDisplayFieldName write SetDisplayFieldName;
    property ParseAvailableItems: boolean read FParseAvailableItems write FParseAvailableItems;
    property AllowDuplicates: boolean read FAllowDuplicates write FAllowDuplicates;
    property ShowNew: boolean read FShowNew write FShowNew;
    property GeneratorSqlId: string read FGeneratorSqlId write FGeneratorSqlId;
    property EditFieldName:String read FEditFieldName write SetEditFieldName;
    property ReadOnly: boolean read GetReadOnly write SetReadOnly default true;
    property MaxLength: integer read FMaxLength write SetMaxLength;
    property Caption: String read GetCaption write SetCaption;
    property CaptionPos: TCaptionPos read GetCaptionPos write SetCaptionPos default cpLeft;
    property CaptionFont: TFont read GetCaptionFont write SetCaptionFont stored true;
    property LookupDataSource : TsfSqlSource read FLookupSqlSource write {Set}fLookupSqlSource; { plr 12/6/99 }
    property Visible : boolean read GetVisible write SetVisible stored False;
    property Modified: boolean read fModified write fModified;
    property ParentFont nodefault;
    property Font stored true;
end;

{ ghl, 03/22/2001 ref ENH #544}
  tSFInputListGrid = class(TSFListGrid, IScanResultAction, IUdvControlCommon)
  private
    fScanAction : TScanAction;
    fLookupSqlSource : TsfSQLSource;
    fValidValues: TfwStringList;
//    fLookupSQL: string;
    fLookupField: string;
    {20030710,rtr: Added support for Validation in the list builder control. Enh# 757.}
    PriorValue: String;
    FVerifyValue : boolean;
    FAllowTyping : boolean;
    FDropDownReturnStr : string ; {rtr 7-31-01 Ref TD# 1786.}
    FChangedByUser: boolean;
    FPersistManualValues: Boolean;
    InHideEdit: boolean;
    FHandlingExit: boolean;  {20021114,cmh: Prevent Multiple error messages. Ref. TD#1380}
    FCharCase: TEditCharCase; {20030710,rtr: Added support for Uppercase in the list builder control. Enh# 588.}
    FValidExpr: String;
    FDependentFields: String;
    LastFieldErrorText: string;
//    procedure SetShowDlgButton(value: boolean); overload;  {20001208,cmh: TD 434} {rtr 1-25-01 Commented out.  Ref TD# 434.}
    procedure CreateDlgButton; override;
    procedure VerifyLookupActive;
    procedure SetLookupSQLSource(value: tSFSqlSource);
    function GetLookupField: string;
    procedure SetLookupField(value: string);
    procedure ListItemDragDrop(Sender, Source: TObject; X,Y: Integer);
    procedure ListItemDragOver(Sender, Source: TObject; X, Y: Integer; State: TDragState; var Accept: Boolean);
    procedure HandleFieldScan(S : String);
    procedure HandleMaskedScan(SL: TStringList);
    procedure HandleKeyBoardEntry(S : String);
    function  IskeyBoardAllowed : Boolean;
    procedure DoOnClick(Sender: TObject);
    procedure HandleAsScan(aControl: TWinControl; NewText: string; Params: TStrings);
  protected
    {20030710,rtr: Added support for Validation in the list builder control. Enh# 757.}
    procedure SetVerifyValue(Value : Boolean);
    function CanEditShow: Boolean; override;
    procedure SetAllowTyping(const Value: boolean);
    function FieldIsValid(const Value: String): boolean;
    procedure CMFocusError(var Message: TMessage); message CM_FocusError;
    procedure IndicateFieldError(const Value: String; RaiseError: Boolean); {rtr 8-1-01 Ref TD# 1948.}
    procedure DoExit; override;
    procedure DoEnter; override;
    function CreateEditor: TInplaceEdit; override;
    function SelectCell(ACol, ARow: Longint): Boolean; override;
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState;
      X, Y: Integer); override;
    procedure KeyDown(var Key: Word; Shift: TShiftState); override; {20031216,rtr: Fixed List builder control does not accept paste text shortcuts until user hits F2, Insert key or click into cell.  Ref TD# 4592.}
    procedure DoPaste(Sender: TObject; var Handled: Boolean);
    function GetEditLimit: Integer; override;
    procedure HideEdit; override;
    procedure SetEditText(ACol, ARow: Longint; const Value: string); override;
    function GetCharCase: TEditCharCase; {20030710,rtr: Added support for Uppercase in the list builder control. Enh# 588.}
    procedure SetCharCase(Value : TEditCharCase); {20030710,rtr: Added support for Uppercase in the list builder control. Enh# 588.}
//    procedure change; override;
    procedure SetNewItemCount(Cnt: Integer);
    procedure UpdateCaption(Params: TStrings = nil); override;
    procedure SetUdvDesigning(Value: TDesigningState); override;
    function GenerateItems(SqlId: string; var Text: string): boolean;
  public
    constructor Create(AOwner: TComponent); override;
    function GetBoundsRect: TRect; virtual;
    function AddValue(NewValue: string): Boolean; {20031103,rtr: Fixed TD# 5662.}
    function GetManuallyEntered: Boolean;
    procedure VerifyLookupParameters;
    procedure FillDataValues(
      Value: String;
      Overwrite: boolean;
      Start: Integer = 1;
      Increment: Integer = 0;
      EndAt: Integer = 0
      );
    procedure ShowFillWizard(HostControl: TWinControl);
    procedure UserSetValue(Value: String);
    property ValidValues: TfwStringList write fValidValues;
    property LookupSqlSource: TsfSQLSource read fLookupSQLSource write SetLookupSQlSource;      {cmh 20000901}
    {20030710,rtr: Added support for Validation in the list builder control. Enh# 757.}
    property VerifyValue : boolean read FVerifyValue write SetVerifyValue;
    property AllowTyping: boolean read FAllowTyping write SetAllowTyping default True;
    property CharCase : TEditCharCase read GetCharCase write SetCharCase; {20030710,rtr: Added support for Uppercase in the list builder control. Enh# 588.}
    property BoundsRect: TRect read GetBoundsRect;
    property ValidExpr: String read FValidExpr write FValidExpr;
    property DependentFields: String read FDependentFields write FDependentFields;
    property ManuallyEntered: Boolean read GetManuallyEntered;
    property PersistManualValues: boolean read FPersistManualValues write FPersistManualValues;
  published
    procedure DlgButtonOnClick(Sender: TObject);
    property LookupField: string read GetLookupField write SetLookupField;
    property ShowDlgButton : boolean read GetShowDlgButton write SetShowDlgButton stored false; {20001208,cmh: TD 434}
    property ScanAction : TScanAction read fScanAction write FScanaction default saAccept;
    property Options stored false;
    property Modified stored false;
    property DefaultColWidth stored false;
    property DefaultRowHeight stored false;
    property FixedCols stored false;
    property FixedRows stored false;
    // property ColCount stored false; // Must store! Needed by ColWidths reader!
    property RowCount stored false;
    property MaxLength stored false;
    property ParentFont nodefault;
    property Font stored true;
    property CaptionFont stored true;
  end;


  tSFDBListGrid = class(TSFListGrid, IUdvControlCommon)
  private
    FDataLink: TFieldDataLink;
    procedure DataChange(Sender: TObject);
    function GetDataField: string;
    function GetDataSource: TDataSource;
    procedure SetDataField(const Value: string);
    procedure SetDataSource(Value: TDataSource);
    procedure UpdateData(Sender: TObject);
    procedure CMExit(var Message: TCMExit); message CM_EXIT;
    procedure CMHintShow(var Message: TMessage); message CM_HintShow;
    procedure UpdateCaption(Params: TStrings = nil); override;
    procedure SetUdvDesigning(Value: TDesigningState); override;
  protected
    procedure Change;// override;
    function EditCanModify: Boolean;// override;
    procedure KeyDown(var Key: Word; Shift: TShiftState); override;
    procedure KeyPress(var Key: Char); override;
    procedure Loaded; override;
    procedure Click; override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    function ExecuteAction(Action: TBasicAction): Boolean; override;
    function UpdateAction(Action: TBasicAction): Boolean; override;
  published
    property DataField: string read GetDataField write SetDataField;
    property DataSource: tDataSource read GetDataSource write SetDataSource;
  end;

implementation

uses
  delstgdlg
  , sfDlgs
  { ghl, 03/09/2001 ref ENH #544}
  ,StrCache
  ,UdvDlg
  ,UDVDlgBasic
  ,UdvCtrl
  ,FWVars
  ;

const
  sUnlikely = '("@~!)';

function tSFListGrid.LoadComboGlyph: HBitmap;
begin
   result:= LoadBitmap(0, PChar(32738));  { ??? }
end;

constructor tSFListGrid.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  Font.OnChange := nil;
  AboveGap := 5; LeftGap :=10;
  FEditFieldName := '';
  FHidden := false;
  FLabel := nil;
  fCaptionPos := cpLeft;
  fDelim := ';'; {20001218,cmh: semicolon as default - default was commented out earlier - TD 355}
  FOriginalValues := TfwStringList.Create;
  FReturnFields := '';
  FDisplayFieldName := '';
  FParseAvailableItems := true;
  FAllowDuplicates := false;
  FShowNew := true;
  FDesigningState := dsNone;
  FOriginalCaption := '';
  fMaxLength := 255;
  FixedCols := 0;
  FixedRows := 0;
  ColCount := 2;
  ColWidths[1] := 0;
  RowCount := 5000;
(* 20050913,rtr: Fixed "Control has no parent window" error when adding List to an Input UDV. Not seen externally. Ref TD# 7916.
  ColWidths[0] := self.width-1; // not needed here (was being set in UDVEMain.pas)
*)
  self.ScrollBars := ssNone;
  EditorMode := true;
  options := [goEditing,goTabs];
  Font.Height := 12;
  DefaultRowHeight := Font.Height +3;

  fBtnControl  := nil;
  DlgButton := nil;

//  DlgButton.Visible := {true}false;	  {20001208,cmh: TD#434} {rtr 1-25-01 Commented out.  Ref TD# 434.}
  FForceHideDlgButton := True; {rtr 1-25-01 Hide button when lookup is not defined. Ref TD# 434.}

  OnSelectCell := SelectCellEvent;
  OnSetEditText := SetEditTextEvent;

  OnKeyUp := OnKeyUpEvent;
//  ReadOnly := true; {rtr 1-25-01 Commented out.  Ref TD# 434.}
  Color := GetControlBackgroundColor(self) ;  {20001122,cmh: fix background color in display UDV }
end;

procedure tSFListGrid.Loaded; {rtr 1-25-01 Added}
begin
  inherited;
  {rtr 1-25-01 Fixed problem which required user to click list grid
    repeatedly to begin in place edit.  Ref TD# 717.}
  SelectCell(0,0);
end;

destructor tSFListGrid.Destroy;
begin
  FOriginalValues.free;
  inherited;
end;

procedure tSFListGrid.SetBounds(ALeft, ATop, AWidth, AHeight: Integer);
begin
  inherited SetBounds(ALeft, ATop, AWidth, AHeight);
  if assigned(DlgButton) then
    begin
      DlgButton.SetBounds(0,0,17,17);
      FBtnControl.parent := parent;  {parent must be reset for visibility}
      FBtnControl.Top := self.top;
      FBtnControl.Left :=  Left+Width+5;
    end;
  DefaultColWidth := aWidth;       // Ref. TD#6785
  If Assigned(FLabel) Then FLabel.PositionCaption;
end;

procedure tSFListGrid.SetDelimiter(value: String);
begin
  fDelim := trim(value);
end;

function tSFListGrid.GetDelimiter: string;
begin
  result := fDelim;
end;

procedure TSFListGrid.SetReturnFields(value: string);
begin
  FReturnFields := trim(value);
  //if FReturnFields <> ''
  //  then ReadOnly := true;
end;

procedure TSFListGrid.SetDisplayFieldName(value: string);
begin
  FDisplayFieldName := trim(value);
end;

function TSFListGrid.DlgButtonRect: TRect;
begin
  Result := Rect(Left+Width+5,Top,Left+Width+5+17,Top+17);
  if EnableBigButtons then
    begin
      Result.Right := Result.Left + trunc((Result.Right-Result.Left) * AdjustmentFactor);
      Result.Bottom := Result.Top + trunc((Result.Bottom-Result.Top) * AdjustmentFactor);
    end;
end;

procedure tSFListGrid.CreateDlgButton;
begin
  fBtnControl  := tWinControl.create(self);
{     fBtnControl.Height := 17; fBtnControl.Width := 17;
      fBtnControl.Top := self.top; fBtnControl.Left := Left+Width +5;
  20040819,ht: Setting height,width,top,and left will call setbounds 4 times
               in TControl class. So, refactor to call only 1 }
  fBtnControl.BoundsRect := DlgButtonRect;
  fBtnControl.parent := parent;
  fBtnControl.visible := true;

  DlgButton := tSfSpeedButton.Create(self);
  DlgButton.parent := (fbtnControl);
//  DlgButton.SetBounds(0,0,17,17);
  DlgButton.Glyph.Handle := LoadComboGlyph;
  DlgButton.SetBounds(0,0,fBtnControl.Width,fBtnControl.Height);
  DlgButton.Flat := False;
end;

procedure tSFListGrid.SetShowDlgButton(value: boolean);
begin
  if Value And not assigned(DlgButton)
    then CreateDlgButton;
  if assigned(DlgButton) then
    begin
      fbtncontrol.parent := parent;  {parent must be reset for visibility}
      // Move this button to the left when hidden so as not to cause scroll bars
      DlgButton.Visible := value And (not FForceHideDlgButton); {rtr 1-25-01 Ref TD#434.}
      FBtnControl.Visible := DlgButton.Visible;
      if Self.ReadOnly  then DlgButton.Visible := false;     {20001017,cmh: trapping button confusion TD#273}
      if not Self.Visible  then DlgButton.Visible := false;  {20001017,cmh: trapping button confusion TD#273}
    end;  
end;

{rtr 1-25-01 Commented out.  Ref TD# 434.}
//procedure tSFInputListGrid.SetShowDlgButton(value: boolean);  {20001208,cmh: TD 434}
//begin
//  inherited SetShowDlgButton(Value);
//  if assigned(fLookupSqlSource) and (not hidden) then   {20001208,cmh: TD 434}
//    DlgButton.Visible := true
//  else
//    DlgButton.Visible := false;
//end;

function tSFListGrid.GetShowDlgButton: boolean;
begin
  if not assigned(DlgButton) then
    result := false
  else
    result := DlgButton.Visible;
end;

procedure tSFListGrid.SetTextValue(value: string);
begin
  UpdateFromValue(value, false);
end;

procedure tSFListGrid.ClearValues;
begin
  Cols[0].Clear;
  Cols[1].Clear;
  RowCount := 0;
end;

procedure tSFListGrid.UpdateFromValue(value: string; HandleDisplayFieldName: boolean; IsOriginalValues: boolean = false);
var
  sl : TfwStringList;
  i : integer;
  Disp: string;
begin
  sl := TfwStringList.create;
  try
    Value := RefToStr(Value);
    if Value = '' then
      begin
        ClearValues;
        exit;
      end;
    ParseStringToList(value,[FDelim[1]],sl,true);
    if sl.count > 0 then
      begin
        if IsOriginalValues
          then FOriginalValues.assign(SL);
        RowCount := SL.Count;
        if (Length(trim(FDelim)) = 2) and HandleDisplayFieldName then
          begin
            for i := 0 to SL.Count -1 do
              begin
                ParseInTwo(SL[i], FDelim[2], Disp, Value);
                Cells[0,i]:= Disp;
                Cells[1,i]:= Value;//SL[i];
              end;
          end
         else
          begin
            for i := 0 to SL.Count -1 do
              begin
                Cells[0,i]:= SL[i]; // Display
                Cells[1,i]:= SL[i]; // Value
              end;
          end;
        if visibleRowCount < RowCount then
          ScrollBars := ssVertical;
      end;
    invalidate; {gns, 13 Nov 2002 -  20021113,gns: Added to cause update list to refresh faster}
  finally
    sl.free;
  end;
end;

function tSFListGrid.GetTextValue: string;
var
  i: integer;
begin
  result := sEmpty;
  if RowCount > 0 then
    for i := 0 to RowCount -1 do
      if TrimRight(Cells[1,i]) <> sEmpty then
        begin
          if result = sEmpty then
            result := TrimSpaces(Cells[1,i])
           else
            Cat(result, fDelim[1]+TrimSpaces(Cells[1,i]));
        end;
end;

procedure tSFListGrid.SetTextDisplay(value: string);
var
  sl : TfwStringList;
  i : integer;
begin
  sl := TfwStringList.create;
  try
    Value := RefToStr(Value);
    ParseStringToList(value,[FDelim[1]],sl,true);
    if sl.count > 0 then
      begin
        RowCount := SL.Count;
        for i := 0 to SL.Count -1 do
          begin
            Cells[0,i]:= SL[i]; // Display
          end;
        if visibleRowCount < RowCount then
          ScrollBars := ssVertical;
      end;
    invalidate; {gns, 13 Nov 2002 -  20021113,gns: Added to cause update list to refresh faster}
  finally
    sl.free;
  end;
end;

function tSFListGrid.GetTextDisplay: string;
var
  i: integer;
begin
  result := sEmpty;
  if RowCount > 0 then
    for i := 0 to RowCount -1 do
      if TrimRight(Cells[0,i]) <> sEmpty then
        begin
          if result = sEmpty then
            result := TrimSpaces(Cells[0,i])
           else
            Cat(result, fDelim[1]+TrimSpaces(Cells[0,i]));
        end;
end;

procedure tSFListGrid.SetEditTextEvent;
begin
  UpdateRowCount;
end;

procedure tSFListGrid.SelectCellEvent;
begin
  UpdateRowCount;
end;

procedure tSFListGrid.UpdateRowCount;
begin
// 20030820,cmh: Deleted setting of scrollbars here. Ref. TD# 5309
//  if RowCount> VisibleRowCount then
//    begin
//      self.ScrollBars := ssVertical;
//    end
//  else
//    self.ScrollBars := ssNone;
  if Cells[0, rowcount-1]<> sEmpty  then
    begin
      RowCount := RowCount+1;
    end;
  if (Row - TopRow) >= VisibleRowCount then  //20030820,cmh move top row up to keep values in view Ref. TD# 5309
     TopRow := TopRow + 1;
  if (Row - TopRow) < 0 then  //20030820,cmh move top row downto keep values in view Ref. TD# 5309
     TopRow := Row;
end;

procedure tSFListGrid.SetEditFieldName(Value: string);
begin
  FEditFieldName := value;
end;

function tSFListGrid.GetReadOnly;
begin
  result := fReadOnly;
end;

procedure tSFListGrid.SetReadOnly(value: boolean);
begin
  fReadOnly := value;
  if fReadOnly or not Among(FReturnFields,['',FEditFieldName]) then
     options := [goTabs, goThumbTracking]
  else
     options := [goEditing,goTabs,goThumbTracking];
//  ShowDlgButton := not ReadOnly; {rtr 1-25-01 Commented out.  Ref TD# 434.}
end;

procedure tSFListGrid.SetMaxLength(value: integer);
begin
  if Value <> 0
    then fMaxLength := value
    else fMaxLength := 255;
  if (InplaceEditor <> nil) and (TMaskEdit(InplaceEditor).MaxLength <> fMaxLength)
    then TMaskEdit(InplaceEditor).MaxLength := fMaxLength;
end;

procedure  tSFListGrid.OnKeyUpEvent(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
//  if Length(Cells[Col,Row])>fMaxLength then
//    Cells[Col,Row] := copy(Cells[Col,Row],1,fMaxLength);
  UpdateRowCount; //20030820,cmh: Ref. TD# 5309
end;

procedure tSFListGrid.SetCaption(Value : String); { plr }
begin
  FOriginalCaption := Value;
  if FLabel = nil
    then FLabel := SetLabelCaption(Self, FLabel, Value)
    else FLabel.Caption := Value;
//  if assigned(FLabel) then
//    begin
      FLabel.Center := UdvCenterLeftPositionedCaptions;
      FLabel.PositionCaption;
//    end;
  UpdateCaption;
end;

function tSFListGrid.GetCaption : String; { plr }
begin
  if FLabel = nil
    then Result := sEmpty
    else
      begin
        //Result := FLabel.Caption;
        result := FOriginalCaption;
        if pos(#13,Result) <> 0
          then Result[pos(#13,Result)] := ';';
      end;
end;

procedure tSFListGrid.SetUdvDesigning(Value: TDesigningState);
begin
  FDesigningState := Value;
  UpdateCaption;
end;

procedure tSFListGrid.SetCaptionFont(Value : TFont); { plr }
begin
  if FLabel <> nil
    then FLabel.Font := Value;
end;

function tSFListGrid.GetCaptionFont : TFont; { plr }
begin
  if FLabel = nil
    then Result := Font
    else Result := FLabel.Font;
end;

procedure tSFListGrid.CMParentFontChanged(var Message: TMessage);
begin
  //inherited;
  if ParentFont
    then ApplyGlobalFontDef(Font);
  if FLabel <> nil
    then FLabel.ParentFont := ParentFont;
end;

function tSFListGrid.GetCaptionPos: TCaptionPos;
begin
  If Assigned(FLabel)
    Then result := FLabel.CaptionPos
    else result := cpLeft;
end;

procedure tSFListGrid.SetCaptionPos(Value : TCaptionPos); { plr }
begin
  If Assigned(FLabel)
    Then FLabel.CaptionPos := Value;
end;

procedure tSFListGrid.SetParent(AParent : TWinControl);
begin
  inherited SetParent(AParent);
  if FLabel <> nil
    then FLabel.Parent := AParent;
end;

function tSFListGrid.GetVisible: boolean;
begin
  Result := inherited Visible;
end;

procedure tSFListGrid.SetVisible(const Value: boolean);
begin
  inherited Visible := Value;
  if Assigned(FLabel)
    then FLabel.Visible := Value;
  SetShowDlgButton(value); { 20001013,cmh: not hiding button when list was hidden by parameters}
end;

constructor tSFDBListGrid.Create(AOwner: TComponent);
begin
  FDataLink := TFieldDataLink.Create;
  inherited Create(AOwner);
//  inherited ReadOnly := True; {rtr 1-25-01 Commented out.  Ref TD# 434.}
  FDataLink.Control := Self;
  FDataLink.OnDataChange := DataChange;
  FDataLink.OnUpdateData := UpdateData;
end;

destructor tSFDBListGrid.Destroy;
begin
  FDataLink.OnDataChange := nil;
  FDataLink.OnUpdateData := nil;
  FDataLink.Free;
  FDataLink := nil;
  inherited Destroy;
end;

procedure tSFDBListGrid.Loaded;
begin
  inherited Loaded;
//  ResetMaxLength;
  ReadOnly := true;
  ShowHint := true;
  if (csDesigning in ComponentState) then DataChange(Self);
end;

procedure tSFDBListGrid.KeyDown(var Key: Word; Shift: TShiftState);
begin
  inherited KeyDown(Key, Shift);
  if (Key = VK_DELETE) or ((Key = VK_INSERT) and (ssShift in Shift)) then
    FDataLink.Edit;
end;

procedure tSFDBListGrid.KeyPress(var Key: Char);
begin
  inherited KeyPress(Key);
  if (Key in [#32..#255]) and (FDataLink.Field <> nil) and
    not FDataLink.Field.IsValidChar(Key) then
  begin
    MessageBeep(0);
    Key := #0;
  end;
  case Key of
    ^H, ^V, ^X, #32..#255:
      FDataLink.Edit;
    #27:
      begin
        FDataLink.Reset;
  //?      SelectAll;
        Key := #0;
      end;
  end;
end;

function tSFDBListGrid.EditCanModify: Boolean;
begin
  Result := FDataLink.Edit;
end;


procedure tSFDBListGrid.Change;
begin
  FDataLink.Modified;
//  inherited;
end;

function tSFDBListGrid.GetDataSource: TDataSource;
begin
  Result := FDataLink.DataSource;
end;

procedure tSFDBListGrid.SetDataSource(Value: TDataSource);
begin
  if not (FDataLink.DataSourceFixed and (csLoading in ComponentState)) then
    FDataLink.DataSource := Value;
  if Value <> nil then Value.FreeNotification(Self);
end;

function tSFDBListGrid.GetDataField: string;
begin
  Result := FDataLink.FieldName;
end;

procedure tSFDBListGrid.SetDataField(const Value: string);
begin
  if not (csDesigning in ComponentState) then
  FDataLink.FieldName := Value;
end;

procedure tSFDBListGrid.DataChange(Sender: TObject);
begin
  if FDataLink.Field <> nil then
    begin
      TextValue := FDataLink.Field.AsString
    end;
end;

procedure tSFDBListGrid.UpdateData(Sender: TObject);
begin
//?  ValidateEdit;
  FDataLink.Field.Text := TextValue;
end;

procedure tSFDBListGrid.CMExit(var Message: TCMExit);
begin
  try
    FDataLink.UpdateRecord;
  except
    SetFocus;
    raise;
  end;
  DoExit;
end;

procedure tSFDBListGrid.CMHintShow(var Message: TMessage);
begin
  with TCMHintShow(Message) do
  begin
    with HintInfo^ do
    begin
      Result := 0; // show that we want a hint
      HintStr := WrapText(TextValue,#13,[Delimiter[1]],200);
    end;
  end;
end;

procedure tSFDBListGrid.UpdateCaption(Params: TStrings = nil);
var
  S: String;
begin
  if FLabel = nil
    then exit;
  if UdvExpressionsInCaptionsEnabled and IsExpression(FOriginalCaption) then
     begin
       if (FDesigningState <> dsNone)
         then FLabel.Caption := sExpressionCaption
         else if (DataSource <> nil)
             and (DataSource.Owner <> nil)
             and (DataSource.Owner Is TSfSqlSource)
             and (CalcStringFieldExpr(TSfSqlSource(DataSource.Owner).LastParamValues, FOriginalCaption, S) = -1)
         then FLabel.Caption := _(S);
       FLabel.PositionCaption;  
     end;    
end;

procedure tSFDBListGrid.SetUdvDesigning(Value: TDesigningState);
begin
  inherited;
end;

procedure tSFDBListGrid.Click;
var
  SL: TStringList;
begin
  inherited;
  SL := TStringList.Create;
  try
    SL.Text := Translate(TextValue,Delimiter[1],#13#10);
    ViewStrings('List Items', SL);
  finally
    SL.Free;
  end;
end;

function tSFDBListGrid.ExecuteAction(Action: TBasicAction): Boolean;
begin
  Result := inherited ExecuteAction(Action) or (FDataLink <> nil) and
    FDataLink.ExecuteAction(Action);
end;

function tSFDBListGrid.UpdateAction(Action: TBasicAction): Boolean;
begin
  Result := inherited UpdateAction(Action) or (FDataLink <> nil) and
    FDataLink.UpdateAction(Action);
end;

constructor tSFInputListGrid.Create(aOwner: tComponent);
begin
  Inherited Create(aOwner);
//  ReadOnly := false; {rtr 1-25-01 Commented out.  Ref TD# 434.}
//  ShowDlgButton := {true}false; {rtr 1-25-01 Commented out.  Ref TD# 434.}
  OnDragDrop := ListItemDragDrop;
  OnDragOver := ListItemDragOver;
  FLookupField := sEmpty;
  {20030710,rtr: Added support for Validation in the list builder control. Enh# 757.}
  FVerifyValue := True ;
  FAllowTyping := true;
  FDropDownReturnStr := '';
  FValidExpr := '';
  FDependentFields := '';
  PriorValue := '';
  FPersistManualValues := True;
  InHideEdit := false;
  LastFieldErrorText := '';
  FChangedByUser := false;
  self.OnClick := DoOnClick;
  self.Options :=  Options + [goRowMoving];
end;

procedure tSFInputListGrid.CreateDlgButton;
begin
  inherited;
  DlgButton.OnClick := DlgButtonOnClick;
end;

{20031216,rtr: Fixed List builder control does not accept paste text shortcuts until user hits F2, Insert key or click into cell.  Ref TD# 4592.}
procedure tSFInputListGrid.KeyDown(var Key: Word; Shift: TShiftState);
var
  B: Boolean;
begin
  // Since the grid now has 2 columns, we need to avoid tabbing to
  //   the "hidden" (actually, zero width) column.  Do this before calling
  //   the inherited method.
  if Key = VK_TAB then
    begin
      if Shift = []
        then Key := VK_DOWN
        else if Shift = [ssShift]
        then Key := VK_UP;
    end;
  inherited KeyDown(Key, Shift);
  if ssCtrl in Shift Then
    case Key of
      VK_V: DoPaste(Self, B);
    end
  else if ssShift in Shift Then
    case Key of
      VK_INSERT: DoPaste(Self, B);
    end
  else if ssAlt in Shift Then {20040702,rtr: List builder does not honor Alt-<down arrow> to open picker. Ref TD# 6207.}
    case Key of
      VK_DOWN:
        begin
          if assigned(DlgButton)
            then DlgButton.Click;
          Key := 0;
        end;
    end;
end;

procedure tSFInputListGrid.MouseDown(Button: TMouseButton; Shift: TShiftState;
      X, Y: Integer);
var
  SL: TStringList;
  I: integer;
begin
  If (Button = mbRight) And (ssCtrl In Shift) Then
     begin
       SL := TStringList.Create;
       try
        SL.Add('r,c0,c1');
        for I := 0 to RowCount-1 do
          SL.Add(format('%d,%s,%s',[I,Cells[0,I],Cells[1,I]]));
        TextScrollStringList('List Diagnostics', SL);
       finally
         SL.Free;
       end;
     end
    else inherited;
end;

function tSFInputListGrid.GetEditLimit: Integer;
begin
  result := fMaxLength;
end;

{20031216,rtr: Fixed Pasting of multiline text in list builder control.  Ref TD# 5870.}
procedure tSFInputListGrid.DoPaste(Sender: TObject; var Handled: Boolean);
var
  SL : TfwStringList;
  I: Integer;
  S: String;
begin
  if Not PasteAllowed(Self)
    then Exit;
  if not assigned(InplaceEditor)
    then ShowEditor;
  with InplaceEditor do
    if Visible And (IsMasked or ReadOnly Or (SelLength > 0)) Then
      begin
        Handled := False;
        Exit;
      end;

  Handled := True;
  Clipboard.Open;
  SL := TfwStringList.Create;
  try
    HideEditor;
    SL.Text := Clipboard.AsText;
    If SL.Count > 0 Then
      begin
        S := TextValue;
        if S <> ''
          then Cat(S,fDelim[1]);
        For I := 0 To SL.Count-1 Do
          begin
            if (fMaxLength > 0) and (Length(SL[I]) > fMaxLength) then
              begin
                ErrorBox(format(aMaxLengthExceeded,[SL[I]]));
                exit;           
              end;
            if PosStr(SL[I],S) = 0
              then Cat(S,SL[I]+fDelim[1]);
          end;
        if S[Length(S)] = fDelim[1]
          then SetLength(S,Length(S)-1);
        TextValue := S;
        InplaceEditor.Text := SL[0];
      end;
    ShowEditor;
  finally
    SL.Free;
    Clipboard.Close;
  end;
end;

procedure tSFInputListGrid.ListItemDragOver(Sender,
  Source: TObject; X, Y: Integer; State: TDragState; var Accept: Boolean);
begin
  accept := true;
end;

procedure tSFInputListGrid.ListItemDragDrop(Sender, Source: TObject; X,Y: Integer);
var
  i : integer;
  DispName, Value : string;
  HandleDisplayFieldName : boolean;
 begin
  If DragManager.DragObjectCount > 0 Then
  begin
      HandleDisplayFieldName :=   (FDisplayFieldName <> '') and (FDisplayFieldName <> fLookupField);
      for i := 0 to DragManager.DragObjectCount-1 do
      begin
         Value := DragManager.GetDragObjectValue(i,fLookupField);
         if not FoundInDelimStr(Value, Cols[1].Text, sCRLF) then  //if value not already selected
         begin
            if  HandleDisplayFieldName then  //if Display Name needs to be handled separetly
               DispName := DragManager.GetDragObjectValue(i,FDisplayFieldName)
            else
               DispName := Value;
            AddToList(DispName,Value);
            if Source Is TsfDBGrid then
            begin
              //Dont Display this item in Available Items DBGrid
              TsfDBGrid(Source).AddToExcludeFromPaintList(DispName);       //Hetal
            end;

         end;
      end;

      if visibleRowCount < RowCount then
          ScrollBars := ssVertical;
      invalidate;

      DragManager.ClearDragList;
  end;
end;

procedure tSFInputListGrid.SetLookupSQLSource(value: tSFSQLSource);
var
  SqlLines, FieldSL : TfwStringList;
begin
  fLookupSQLSource := value;
  FForceHideDlgButton := False; {rtr 1-25-01 Hide button when lookup is not defined. Ref TD# 434.}
  ShowDlgButton := assigned(value);
//  If assigned(value)  then  {rtr 1-25-01 Commented out.  Ref TD# 434.}
//    ShowDlgButton := false; {20001208, cmh: TD434}
  {20030710,rtr: Added support for Validation in the list builder control. Enh# 757.}
  If FLookupSqlSource <> Nil Then
     begin
       SqlLines := TfwStringList.Create;
       FieldSL := TfwStringList.Create;
       try
         SqlLines.Assign(GetSqlFromList(FLookupSqlSource.DatabaseName, FLookupSqlSource.SelectSQLId));
         GetSelectFields(SqlLines, FieldSL);
         If FVerifyValue
            And (ValidColName(FLookupSqlSource.DatabaseName, SqlLines, FieldSL, LookupField) = '')
           Then AllowTyping := False;
       finally
         SqlLines.Free;
         FieldSL.Free;
       end;
     end;
end;

procedure tSFInputListGrid.VerifyLookupActive;
var
  I: Integer;
  SL: TfwStringList;
begin
  If FLookupSqlSource.DataSource.Dataset.Active
    Then Exit;
  SL := TfwStringList.Create;
  try
    with FLookupSqlSource.DataSource.Dataset as TQuery do
      for I := 0 to Params.Count-1 do {rtr 5-18-01 Added error handling for undefined params.  Ref TD# 1466.}
        if Params[I].DataType = ftUnknown Then
           If SL.IndexOf(Params[I].Name) = -1 {20031109,rtr: Monir tweak}
             Then SL.Add(Params[I].Name);
    If SL.Count = 0
      Then Raise QueryException.Create(Nil, 'Error preparing/openning lookup query.', TVersaQuery(FLookupSqlSource.DataSource.Dataset))
      Else
        begin
          ApplyGlobalDataInfoToParams(SL); {20040128,rtr: Added GlobalDataInfo to replace field/column names with names which are familiar to end users.  Ref Enh# 809.}
          Raise QueryException.Create(Nil, sPleaseEnterValuesFor+#13+StringListToString(SL, #13), TVersaQuery(FLookupSqlSource.DataSource.Dataset), False);
        end;
  finally
    SL.Free;
  end;
end;

procedure tSFInputListGrid.FillDataValues(
  Value: String;
  Overwrite: boolean;
  Start: Integer = 1;
  Increment: Integer = 0;
  EndAt: Integer = 0
  );

  function Check(const S: string): string;
  begin
    if FCharCase = ecUpperCase
      then result := Uppercase(S)
      else result := S;
  end;

var
  Cnt: Integer;
  S, Temp: String;
begin
  FDropDownReturnStr := sTilde;
  HideEditor;
  try
    if Overwrite
      then S := ''
      else S := TextValue;
    if (EndAt > 0) and (Increment > 0) then
      begin
        Cnt := Start;
        while Cnt <= EndAt do
          begin
            if S <> ''
              then Cat(S,fDelim[1]);
            if FCharCase = ecUpperCase
              then Temp := Uppercase(format(Value,[Cnt]))
              else Temp := format(Value,[Cnt]);
            if not FieldIsValid(Temp) then
              begin
                IndicateFieldError(Temp, True);
                exit;
              end;
            Cat(S,Temp);
            Inc(Cnt, Increment);
          end;
        if FCharCase = ecUpperCase
          then TextValue := Uppercase(S)
          else TextValue := S;
      end;
  finally
    ShowEditor;
  end;
end;

procedure tSFInputListGrid.ShowFillWizard(HostControl: TWinControl);
var
  UDV: TWinControl;
begin
  with TFillValuesDialog.Create(nil) do
    begin
      UDV := TWinControl(GetParentByClassName(HostControl, 'TSfUdv'));
      if assigned(UDV)
        then ContextId := TsfUDV(UDV).UdvId+'~'+LookupField;
      try
        MaxRequired := true;
        if ShowModal = mrOk then
          begin
            FillDataValues(
                     FillFormat,
                     OverwriteCheckBox.Checked,
                     StartEdit.Value,
                     IncrementEdit.Value,
                     MaxEdit.Value
                     );
          end;
      finally
        Free;
      end;
    end;
  DoEnter;  
end;

procedure tSFInputListGrid.UserSetValue(Value: String);
begin
  TextValue := Value;
  if assigned(UserInputChangeProc)
    then UserInputChangeProc(Self, fLookupField, FLabel.Caption, Value);
end;

procedure tSFInputListGrid.SetNewItemCount(Cnt: Integer);
begin
  ClearValues;
  RowCount := Cnt+1; //add 1 to fix some issues when clicking on empty cell to begin editing
end;

resourcestring
sGenerate = 'Generate';
sGeneratePrompt = 'Number of %s to generate:';

function tSFInputListGrid.GenerateItems(SqlId: string; var Text: string): boolean;
var
  Value: String;
  I: Integer;
begin
  if EnablePopUpKeyboard    { hide popup keyboard - plr 1/27/03 }
    then HidePopupKeyboard;
  result := false;
  Value := '';
  if SfInputQuery(sGenerate, format(sGeneratePrompt,[TrimChar(Caption,'*')]), Value) then
    begin
      I := StrToIntDef(Value,-1);
      if I < 1
        then Raise Exception.Create(sInvalidPositiveNumber);
      //Text := '1,2,3,4';
      Text := GetQueryWithParamsResultSet(FwDatabaseName, SqlId, [Value_var_name+'='+Value], Nil);
      result := true;
    end;
end;


procedure tSFInputListGrid.DlgButtonOnClick(Sender: TObject);
var
  TargetFields: string;
  Ok: boolean;
begin
  try
    if not FieldIsValid(Cells[Col,Row]) then
      begin
        IndicateFieldError(Cells[Col,Row], True); {Ref TD# 1948.}
        exit;
      end;
  except
    IndicateFieldError(Cells[Col,Row], False); {Fixed Error raised during field validation not holding focus on related field. Ref TD# 1990.}
    Raise;
  end;

  if Screen.ActiveControl is TSFDBInputEdit then    {20021202,cmh: do control exit when clickedRef TD# 4080}
    begin
//      if assigned(TSFDBInputEdit(Screen.ActiveControl).onExit) then
//        TSFDBInputEdit(Screen.ActiveControl).onExit(Screen.ActiveControl);
      Self.SetFocus;
    end;
  if EnablePopUpKeyboard    { hide popup keyboard after setfocus! }
    then HidePopupKeyboard;

 if assigned(fLookupSQLSource) then                    { plr 11/6/2000 }
    begin
      fLookupSQLSource.RefreshIfParamsChanged;  { plr 11/6/2000 }
      VerifyLookupActive;
//      if not fLookupSQLSource.Active {20041015,rtr: Better handling of List Picker configuration errors.}
//        then Raise Exception.Create(Format('Lookup query %s failed. Check param values.',[fLookupSQLSource.Name]));
    end
   else
    begin
      ShowFillWizard(self);
      exit;               { 20001208,cmh }
    end;
 if FReturnFields <> ''
   then TargetFields := FReturnFields
   else TargetFields := LookupField;
 if GeneratorSqlId <> '' then
   begin
     if GenerateItems(GeneratorSqlId, FDropDownReturnStr) then
       begin
         ParseStrToStringList(FDropDownReturnStr, [fDelim], Cols[0], True);
         FOriginalValues.Assign(Cols[0]);
         if visibleRowCount < RowCount then
           ScrollBars := ssVertical;
       end;
   end
  else if ShowDelimitedStringDialog(self, LookupSqlSource, Cols[1], Cols[0], fDelim, TargetFields,
    DisplayFieldName, SetNewItemCount, ParseAvailableItems, AllowDuplicates, ShowNew) then
   begin
     FDropDownReturnStr := TextValue;
     FOriginalValues.Assign(Cols[1]);
     if visibleRowCount < RowCount then
       ScrollBars := ssVertical;
   end;
 SetEditText(Col, Row, sUnlikely);
end;

function tSFInputListGrid.SelectCell(ACol, ARow: Longint): Boolean;
var
  ValueOK: Boolean;
begin
  try
    ValueOK := FieldIsValid(Cells[Col,Row]);
  except
    IndicateFieldError(Cells[Col,Row], False); {Fixed Error raised during field validation not holding focus on related field. Ref TD# 1990.}
    Raise;
  end;
  if ValueOK then
     begin
       FDropDownReturnStr := sEmpty; {Prevent re-validating after user has re-entered field yet hasn't changed anything.}
       inherited DoExit;
     end
  else
    begin
      IndicateFieldError(Cells[Col,Row], True); {Ref TD# 1948.}
    end;
  Result := inherited SelectCell(ACol, ARow);
end;

{20030710,rtr: Added support for Uppercase in the list builder control. Enh# 588.}
function tSFInputListGrid.CreateEditor: TInplaceEdit;
begin
  Result := inherited CreateEditor;
  Result.CharCase := FCharCase;
  Result.OnPaste := DoPaste; {20031216,rtr: Fixed Pasting of multiline text in list builder control.  Ref TD# 5870.}
  TMaskEdit(Result).MaxLength := fMaxLength;
end;

procedure TSFInputListGrid.SetCharCase(Value : TEditCharCase);
begin
  FCharCase := Value;
end;

function TSFInputListGrid.GetCharCase: TEditCharCase;
begin
  Result := FCharCase;
end;

procedure tSFInputListGrid.HideEdit;
begin
  InHideEdit := true;
  try
    inherited;
  finally
    InHideEdit := false;
  end;
end;

{20030710,rtr: Added support for Validation in the list builder control. Enh# 757.}
procedure tSFInputListGrid.SetEditText(ACol, ARow: Longint; const Value: string); // Value holds the contents of one cell, we need to look at the entire contents
var
  TheText: String;
begin
  if Value <> sUnlikely then
    begin
      inherited;
      if not InHideEdit then // ignore when hide editor calls this but nothing is changed
        begin
          // Second column mirrors first when changing manually
          Cells[1, ARow] := Value;
        end;
    end;

  MaxLength := BCScanInfo.ChangeField(Self, Trim(TextValue), MaxLength, HandleAsScan);

  TheText := Trim(TextValue); // expensive to create, so we'll store it
  {rtr - Tilde should never appear in the data so I'll use it to indicate difference with lookup selection}
  If UdvDiagnostics And (TheText <> PriorValue)
    Then DiagnosticsToLog(Format('Field %s changed from "%s" to "%s"',[FLookupField,PriorValue,TheText]));
  FChangedByUser := true;
  If TheText <> Trim(FDropDownReturnStr)
    Then FDropDownReturnStr := sTilde;
  PriorValue := TheText;
end;

function TSFInputListGrid.GetBoundsRect: TRect;
begin
  Result := inherited BoundsRect;
  if not FHidden then
    begin
      UnionRect(Result,Result,DlgButtonRect);
      if assigned(fLabel)
        then UnionRect(Result,Result,fLabel.BoundsRect);
    end;
end;

procedure TSFInputListGrid.SetVerifyValue(Value : Boolean);
begin
  FVerifyValue := Value;
  If Not FVerifyValue {rtr Fixed - setting verify flag always prevents typing into edit fields. Ref TD# 2227.}
    Then AllowTyping := True; {rtr Fixed Typing prohibited for reason of incompatible sql) even though verify flag is off. Ref TD# 2207.}
end;

function TSFInputListGrid.CanEditShow: Boolean;
begin
  result := FAllowTyping and inherited CanEditShow;
end;

procedure TSFInputListGrid.SetAllowTyping(const Value: boolean);
begin
  FAllowTyping := Value;
  if not FAllowTyping // otherwise don't mess with current value of ReadOnly
    then ReadOnly := true;
end;

function TSFInputListGrid.GetManuallyEntered: Boolean;
begin
  Result := (FDropDownReturnStr = sEmpty) And (TextValue <> sEmpty);
end;

procedure TSFInputListGrid.UpdateCaption(Params: TStrings = nil);
var
  S: String;
begin
  if FLabel = nil
    then exit;
  if UdvExpressionsInCaptionsEnabled and IsExpression(FOriginalCaption) then
    begin
      if (FDesigningState <> dsNone)
        then FLabel.Caption := sExpressionCaption
        else if (CalcStringFieldExpr(Params, FOriginalCaption, S) = -1)
        then FLabel.Caption := _(S);
      FLabel.PositionCaption;  
    end;
end;

procedure TSFInputListGrid.SetUdvDesigning(Value: TDesigningState);
begin
  inherited;
end;

(*
procedure TSFInputListGrid.Change;
begin
  inherited;
  {rtr - Tilde should never appear in the data so I'll use it to indicate difference with lookup selection}
  If Trim(Text) <> Trim(FDropDownReturnStr)
    Then FDropDownReturnStr := sTilde;
end;
*)

procedure TSFInputListGrid.VerifyLookupParameters;
begin
  if (not assigned(FLookupSqlSource)) or (TextValue=sEmpty) then
      exit;
  if FLookupSqlSource.Active And {rtr 8-27-01 Fixed - focusing a new field clears list grid control values. Ref TD# 2072.}
     FLookupSqlSource.ParamsHaveChanged then
    TextValue := sEmpty;
end;

procedure TSFInputListGrid.CMFocusError(var Message: TMessage);
var
  F: TCustomForm;
begin
  if CanFocusControl(Self) then
    begin
      F := GetParentForm(Self);
      if F <> nil then
        begin
          F.ActiveControl := nil; // otherwise, setfocus doesn't seem to do the job completely.
          If Visible And Enabled {rtr 3-6-01 Fixed - Error "Cannot focus a disabled or invisible window." when closing Instructions tool window while in edit.  Ref TD# 982.}
            Then SetFocus;
        end;
    end;
  //Row := Message.wParam;
  //ShowEditor;  
  ErrorBox(LastFieldErrorText); {rtr Added error message for invalid value in a field with a lookup. Ref Enh# 332.}
  LastFieldErrorText := '';
end;

procedure TSFInputListGrid.IndicateFieldError(const Value: String; RaiseError: Boolean); {rtr 8-1-01 Ref TD# 1948.}
var
  S: String;
  UDV: TSfUdv;
begin
  MessageBeep(MB_ICONHAND);
  If RaiseError Then
    begin
      if (FLabel <> Nil) and (FLabel.Caption <> '')
        then S := FLabel.Caption
        else If Caption <> sEmpty
        Then S := Caption
        Else S := LookupField;
      //ErrorBox(Format(sInvalidValueXForFieldY,[Value,S])); {rtr Added error message for invalid value in a field with a lookup. Ref Enh# 332.}
      //self.SetFocus;
      LastFieldErrorText := Format(sInvalidValueXForFieldY,[Value,S]);
      UDV := TSfUdv(GetParentByClassName(Self, 'TSfUdv'));
      if Udv <> nil
        then Udv.ErrorControl := self;
      PostMessage(Self.Handle, CM_FocusError, Row, 0);
      //raise EAbort.create('');
    end
   else
    //self.SetFocus;
    PostMessage(Self.Handle, CM_REFOCUS, 0, 0);
end;

function TSFInputListGrid.FieldIsValid(const Value: String): boolean;
var
  aText : string;
  LUSqlSource: TSfSqlSource;

  function PopulateRelatedControls: Boolean;
  var
    sl : TfwStringList;
    ColName: string;
    OneRecReturned: boolean;
  begin
    result := True;
    {rtr Fixed - Dependent input UDV fields are not populated when the user "types" in the value,
      i.e. instead of using the dropdown.  Related fields are now populated as the user tabs out of the
      controlling field, as well as when the user types the value and then hits <Enter> or "Accept". Ref TD# 1786.}
    if (LUSqlSource <> nil) and (FDropDownReturnStr = sTilde) then {was changed by typing/pasting, etc.}
      begin
        if not LUSqlSource.SqlSupportsFilter
          then exit;
        sl := TfwStringList.Create;
        try
          If aText <> sEmpty {rtr Minor optimization...when aText is empty, clear related controls w/o exec'ing the lookup}
            Then
             begin
//              LUSqlSource.Active := false;
               if DisplayFieldName <> ''
                 then ColName := DisplayFieldName
                 else ColName := LookupField;
               Result := LUSqlSource.PopulateRelatedControlValues(SL, ColName, aText, FVerifyValue, OneRecReturned);
             end;
            {doesn't make sense to do the following in this control type}
            //Else LUSqlSource.ClearRelatedControlValues(SL);
            //AssignLookupValues(Parent, sl, LookupField);
        finally
          sl.free;
        end;
      end;
  end;

var
  sl: TfwStringList;
  UDV: TWinControl;
  F: TCustomForm;
begin
  aText := Trim(Value);
  result := false;
  {rtr - disqualify early if possible}
  if (Not FVerifyValue)
     Or (aText = sEmpty)  { allow null on control exit, check for required fields at post }
     Or (not UdvListBuilderValidationEnabled)
     //FDropDownReturnStr is untrustworthy in this control
     //or (FDropDownReturnStr <> sTilde) {was changed by dropdown selection}
     then
     begin
       //List builder does not support populating related controls
       //If FDropDownReturnStr = sTilde
       //  Then PopulateRelatedControls; {we need to do this anyway}
       result := true; {rtr Should follow PopulateRelatedControls. Ref TD# 1980.}
       Exit;
     end;
  {else do verify on typed, non-null value}
  LUSqlSource := FLookupSqlSource;
  UDV := TWinControl(GetParentByClassName(Self, 'TSfUdv'));
  if UDV = nil then
    begin
      F := getparentform(Self);
      if F Is tDelimitedStringDialog then
        begin
          LUSqlSource := tDelimitedStringDialog(F).LookupSqlSource;
          UDV := TWinControl(GetParentByClassName(LUSqlSource.parentcontrol, 'TSfUdv'));
        end;
    end;
  if length(Delimiter) = 1 then
     begin
       if ValidExpr = sEmpty then
         begin
           // Values in the originally loaded control + values returned by the lookup constitute the
           //   full compliment of possibilities.
           Result := OriginalValues.IndexOf(aText) > -1;
           if not Result
             then Result := PopulateRelatedControls // only performs validation in this case
         end;
     end
    else
     begin
       if UdvDiagnostics or ErrorDiagnostics
         then DiagnosticsToLog(format('List control %s dynamic validation skipped for concatenated values (%s).  An explicit Validation expression is required in this case.',[Name,LookupField]));
     end;
  if (not result) and FVerifyValue and (ValidExpr <> sEmpty) then // PopulateRelatedControls may validate against the lookup, do this after
    begin
      sl := TfwStringList.Create;
      try
        if UDV <> nil then
          begin
            TsfUDV(UDV).FetchAllLastParamValues(sl);
            SL.Values[fLookupField] := aText;
            CalcBooleanFieldExpr(SL, ValidExpr, Result);
          end;
      finally
        sl.free;
      end;
    end;
end;

procedure TSFInputListGrid.DoOnClick(sender: TObject);
begin
  inherited;
  if EnablePopupKeyboard then
    ShowPopupKeyboard(self,cAlphaNumericKeyboard);
end;


procedure TSFInputListGrid.DoEnter;
begin
  if BCScanInfo.EnterField(Self, Text, MaxLength)
    then MaxLength := 0;
  inherited;
  if EnablePopupKeyboard
    then ShowPopupKeyboard(self,cAlphaNumericKeyboard);
end;

procedure TSFInputListGrid.DoExit;
var
  ValueOK : boolean;
  UDV: TWinControl;
  F: TCustomForm;
begin
  if FHandlingExit then exit; {cmh: Prevent Multiple error messages. Ref. TD#1380}

  if BCScanInfo.ExitField(Self) and (BCScanInfo.InitialMax > -1)
    then MaxLength := BCScanInfo.InitialMax;

  FHandlingExit := true;      {cmh: Prevent Multiple error messages. Ref. TD#1380}
  try
    inherited;
    F := getparentform(Self);
    if (F Is TSfDialog) and TSfDialog(F).Cancelling
      then exit;
    try                                                          
      ValueOK := FieldIsValid(Cells[Col,Row]);
    except
      IndicateFieldError(Cells[Col,Row], False); {rtr Fixed Error raised during field validation not holding focus on related field. Ref TD# 1990.}
      Raise;
    end;
    if ValueOK then
       begin
         if FChangedByUser and assigned(UserInputChangeProc)
           then UserInputChangeProc(Self, FLookupField, Caption, TextValue, TextDisplay);
         if (Trim(DependentFields) <> sEmpty) and (FDropDownReturnStr <> sEmpty) then
           begin
             UDV := TWinControl(GetParentByClassName(Self, 'TSfUdv'));
             if assigned(UDV)
               then TsfUDV(UDV).ClearDependentFields(DependentFields,fLookupField);
           end;
         FDropDownReturnStr := sEmpty; {rtr Prevent re-validating after user has re-entered field yet hasn't changed anything.}
       end
      else IndicateFieldError(Cells[Col,Row], True); {rtr Ref TD# 1948.}
  finally
    FHandlingExit := false;   {cmh: Prevent Multiple error messages. Ref. TD#1380}
  end;
end;

function tSFInputListGrid.GetLookupField: string;
begin
  result := fLookupField;
end;

procedure tSFInputListGrid.SetLookupField(value: string);
begin
  fLookupField := value;
end;

function tSFInputListGrid.AddValue(NewValue: string): Boolean; {20031103,rtr: Fixed TD# 5662.}
begin
//  Result := False; {20031103,rtr: Fixed TD# 5662.}
  if RowCount > 0 then
    begin
      if not FoundInDelimStr(NewValue, Cols[1].Text, sCRLF) then
        begin
          if TextValue > sEmpty
            then TextValue := TextValue+fDelim[1]+NewValue
            else TextValue := NewValue;
        end;
    end;
  Result := True; {20031103,rtr: Fixed TD# 5662.}
end;

procedure tSFListGrid.SetHidden(const Value: boolean);  {20000908 CMH}
begin
  FHidden := Value;
  if FHidden then
     begin
        SetShowDlgButton(not FHidden); { 20001013,cmh: not hiding button when list was hidden by parameters}
        SetVisible(Not Hidden); {20001013,cmh: was Visible := not hidden, need to do set visible }
     end;
end;

function tSFListGrid.GetHidden: boolean;   {20000908 CMH}
begin
  result := fHidden;
end;

procedure tSFListGrid.AddToList(c0, c1: string);
var
  I, J: integer;
begin
  RowCount := RowCount+1;
  Cells[0,RowCount] := '';
  Cells[1,RowCount] := '';
  J := 0;
  for I := RowCount-1 downto 0 do
    if Cells[0,I] <> '' then
      begin
        J := I+1;
        break;
      end;
  Cells[0,J] := c0;
  Cells[1,J] := c1;
end;

procedure tSFListGrid.DeleteRow(ARow: integer);
var
  i: Integer;
begin
  if RowCount > 1 then
    begin
      for i := ARow to RowCount-2 do
        Rows[i].Assign(Rows[i+1]);
      RowCount := RowCount - 1;
    end
    else
     begin
       cells[0,0] := sEmpty;
       cells[1,0] := sEmpty;
     end;
end;

function tSFListGrid.GetRowDisplayText(ARow: integer): string;
begin
     if ARow >= 0 then
       Result := cells[0,ARow]
      else
        Result := sEmpty;
end;

function tSFListGrid.PasteAllowed(C: TControl): Boolean;
var
  dispObject : IScanResultAction;
  dispObject2 : IDisplayStatus;
begin
  Result := False;
  if C.getinterface(IScanResultAction,dispobject) and not dispobject.IskeyBoardAllowed then
    begin
      if Screen.ActiveForm.getinterface(IDisplayStatus,dispobject2) then
        begin
          MessageBeep(MB_ICONEXCLAMATION);
          dispObject2.ShowStatusMessage('This is a scan-only field.');
        end;
      Exit;
    end;
  Result := True;
end;

{ ghl, 03/09/2001 ref ENH #544}
procedure tSFInputListGrid.HandleFieldScan(S : String);
var
  ParentForm: TCustomForm;
  NextCtrl : TTaborderTestCtrl;
  dispObject : IDisplayStatus;
begin
  case ScanAction of    //
    saAccept:  {String replaces field text}
      begin
        text := S;
        TextValue := text; {cmh, 20011113: TD#2272 Cannot scan into List Control}
      end;
    saOK:       {String Replaces field text and does default form action}
      begin
        text := S;
        ParentForm := GetParentForm(self);
        if assigned(ParentForm) then
          begin
            {20040805,rtr: Refactoring}
            if ParentForm is TUDVdialogBasic then
              TUDVDialogBasic(ParentForm).ExecOk;
          end
        else ParentForm.ModalResult := MROk;
      end ;
    saTab:
      begin
        text := S;
        TextValue := text;{cmh, 20011113: TD#2272 Cannot scan into List Control}
        //the active form must be of type Twincontrol so go ahead and assign it
        try
          NextCtrl := TTaborderTestCtrl(Screen.ActiveForm);
          NextCtrl.SelectNext(Screen.ActiveControl,True,True);
        except
        end;
      end;
    saAdd:   {Concatenates or adds to list}
      begin
      if length(text) > 0 then      {cmh, 20011115: TD#2287 Blank Line in list control}
        text := text +Delimiter+ S
      else
        text := S;
      TextValue  := text; {cmh, 20011113: TD#2272 Cannot scan into List Control}
      end ;
    saScanOnly:
      begin
        text := S;
        TextValue  := text; {cmh, 20011113: TD#2272 Cannot scan into List Control}
      end;
    saIgnore:
      begin
        if Screen.ActiveForm.getinterface(IDisplayStatus,dispobject) then
          begin
            MessageBeep(MB_ICONEXCLAMATION);
            dispObject.ShowStatusMessage('Input from barcode not allowed');
          end;
      end;
  end;    // case

end;

procedure tSFInputListGrid.HandleMaskedScan(SL: TStringList);
var
  TheActiveForm: TForm;
begin
  TheActiveForm := Screen.ActiveForm;
  {20040805,rtr: Refactoring}
  if TheActiveForm is TUDVdialogBasic then
    begin
      with TheActiveForm as TUDVDialogBasic do
      begin
        ApplyParams(SL);
      end;    // with
    end;
end;

procedure  tSFInputListGrid.HandleKeyBoardEntry(S : String);
begin
  case ScanAction of
    saAccept : text := text+S;
    saOK : text := text+S;
    saTab: text := text+S;
    saAdd: text := text+delimiter+S;  {cmh, 20011113: mystery fix - dont know if this is actually being hit}
    saIgnore: text := text+S;
    saScanOnly: ; //Swallow the key
   end;
end;

function tSFInputListGrid.IskeyBoardAllowed : Boolean;
begin
  result := scanAction <> saScanOnly;
end;

procedure tSFInputListGrid.HandleAsScan(aControl: TWinControl; NewText: string; Params: TStrings);
var
  ParentForm: TCustomForm;
  NextCtrl : TTaborderTestCtrl;
  dispObject : IDisplayStatus;
begin
  Cells[0,row] := NewText;
  Cells[1,row] := NewText;
  MaxLength := BCScanInfo.InitialMax;

  ParentForm := GetParentForm(self);

  if Params <> nil then
    begin
      if assigned(ParentForm) and (ParentForm is TUDVdialog)
        then TUDVDialog(ParentForm).UpdateUDVParams(Params{,false});
      exit;
    end;

  case ScanAction of    //
    saAccept:  {String replaces field text}
      begin
        Self.Row := Self.Row + 1;
      end;
    saOK:       {String Replaces field text and does default form action}
      begin
        if assigned(ParentForm) then
          begin
            if ParentForm is TUDVdialogBasic then
              TUDVDialogBasic(ParentForm).ExecOk;
          end
        else ParentForm.ModalResult := MROk;
      end ;
    saTab:
      begin
        try
          NextCtrl := TTaborderTestCtrl(Screen.ActiveForm);
          NextCtrl.SelectNext(Screen.ActiveControl,True,True);
        except
        end;
      end;
    saAdd:   {Concatenates or adds to list}
      begin
(*     if length(text) > 0 then      {cmh, 20011115: TD#2287 Blank Line in list control}
        text := text +Delimiter+ S
      else
        text := S;
 *)
      TextValue  := text; {cmh, 20011113: TD#2272 Cannot scan into List Control}
      end ;
    saScanOnly:
      begin
//        text := S;
//        TextValue  := text; {cmh, 20011113: TD#2272 Cannot scan into List Control}
      end;
    saIgnore:
      begin
        if Screen.ActiveForm.getinterface(IDisplayStatus,dispobject) then
          begin
            MessageBeep(MB_ICONEXCLAMATION);
            dispObject.ShowStatusMessage('Input from barcode not allowed');
          end;
      end;
  end;    // case
end;

end.

