unit GDIText;

interface

uses
  Vcl.Controls, Vcl.Graphics, Winapi.Messages, Winapi.Windows, Vcl.Forms, System.Classes, System.SysUtils, System.Math,
  Dialogs, Winapi.ActiveX, GDI, GDIUtils, GDICtrls;

type
  TGDITextOptions = (
    toNoFitBlackBox,
    toNoFontFallback,
    toDisplayFormatControl,
    toMeasureTrailingSpaces,
    toNoWrap,
    toLineLimit,
    toNoClip,
    toBypassGDI
    );

  TGDITextOptionsSet = Set of TGDITextOptions;

  TStringAlignment = (saNear = 0, saCenter = 1, saFar = 2);

  TGDIText = class(TGDICollectionItem)
  private
    FOptions: TGDITextOptionsSet;
    FFont: TFont;
    FValue: string;
    FAlign: TGDIAlign;
    FPadding: Integer;
    FAlignment: TStringAlignment;
    procedure SetOptions(const Value: TGDITextOptionsSet);
    procedure SetFont(const Value: TFont);
    procedure SetValue(const Value: string);
    procedure SetAlign(const Value: TGDIAlign);
    procedure SetPadding(const Value: Integer);
    procedure SetAlignment(const Value: TStringAlignment);
  protected
    Function GetDisplayName: String; Override;
    procedure Draw(GPGraphics: IGPGraphics); Override;
  public
    constructor Create(Collection: TCollection); override;
    destructor Destroy; override;

    procedure Assign(Source: TPersistent); override;
    function ToStringFormatFlags: TGPStringFormatFlags;
  published
    property Align: TGDIAlign read FAlign write SetAlign default gaTopLeft;
    property Alignment: TStringAlignment read FAlignment write SetAlignment default saNear;
    property Font: TFont read FFont write SetFont;
    property Options: TGDITextOptionsSet read FOptions write SetOptions default [];
    property Padding: Integer read FPadding write SetPadding default 0;
    property Value: string read FValue write SetValue;
  end;

  TGDITextCollection = Class(TGDICollection)
  private
    Function GetItems(Index: Integer): TGDIText;
    Procedure SetItems(Index: Integer; Const Value: TGDIText);
  public
    function Add: TGDIText;

    Property Items[Index: Integer]: TGDIText Read GetItems Write SetItems;
  end;

implementation

{ TGDIText }

procedure TGDIText.Assign(Source: TPersistent);
begin
  if Source is TGDIText then
  begin
    Self.FOptions := TGDIText(Source).Options;
    Self.FValue := TGDIText(Source).Value;
    Self.FAlign := TGDIText(Source).Align;
    Self.FPadding := TGDIText(Source).Padding;
  end
  else
    inherited;
end;

constructor TGDIText.Create(Collection: TCollection);
begin
  inherited;
  FFont := TFont.Create;
  FFont.OnChange := DoChange;
  FPadding := 0;
  FAlign := gaTopLeft;
  FAlignment := saNear;
  FOptions := [];
end;

destructor TGDIText.Destroy;
begin
  FFont.Free;
  inherited;
end;

function TGDIText.GetDisplayName: String;
begin
  If FValue <> '' Then
    Result := FValue
  Else
    Inherited GetDisplayName;
end;

procedure TGDIText.Draw(GPGraphics: IGPGraphics);
var
  Sizef: TGPSizeF;
  StringFormat: IGPStringFormat;
  GdiFont: IGPFont;
begin
  if Self.Value.IsEmpty then
    exit;

  StringFormat := TGPStringFormat.Create(ToStringFormatFlags);
  StringFormat.Alignment := TGPStringAlignment(FAlignment);

  GdiFont := FFont.toGPFont(Control.Canvas.Handle);

  Sizef := GPGraphics.MeasureString(FValue, GdiFont, TGPSizeF.Create(0, 0), StringFormat);

  GPGraphics.DrawString(FValue, GdiFont, Control.GetPoint(FAlign, Sizef.Height, Sizef.Width, FPadding), StringFormat,
    TGPSolidBrush.Create(ColorToGPColor(FFont.Color)));
end;

procedure TGDIText.SetAlign(const Value: TGDIAlign);
begin
  if FAlign <> Value then
  begin
    FAlign := Value;
    DoChange(Self);
  end;
end;

procedure TGDIText.SetAlignment(const Value: TStringAlignment);
begin
  if FAlignment <> Value then
  begin
    FAlignment := Value;
    DoChange(Self);
  end;
end;

procedure TGDIText.SetFont(const Value: TFont);
begin
  if FFont <> Value then
  begin
    FFont.Assign(Value);
    DoChange(Self);
  end;
end;

procedure TGDIText.SetOptions(const Value: TGDITextOptionsSet);
begin
  if FOptions <> Value then
  begin
    FOptions := Value;
    DoChange(Self);
  end;
end;

procedure TGDIText.SetPadding(const Value: Integer);
begin
  if FPadding <> Value then
  begin
    FPadding := Value;
    DoChange(Self);
  end;
end;

procedure TGDIText.SetValue(const Value: string);
begin
  if FValue <> Value then
  begin
    FValue := Value;
    DoChange(Self);
  end;
end;

function TGDIText.ToStringFormatFlags: TGPStringFormatFlags;
begin
  Result := [];
  if toNoFitBlackBox in FOptions then
    Result := [StringFormatFlagsNoFitBlackBox];

  if toNoFontFallback in FOptions then
    Result := Result + [StringFormatFlagsNoFontFallback];

  if toDisplayFormatControl in FOptions then
    Result := Result + [StringFormatFlagsDisplayFormatControl];

  if toMeasureTrailingSpaces in FOptions then
    Result := Result + [StringFormatFlagsMeasureTrailingSpaces];

  if toNoWrap in FOptions then
    Result := Result + [StringFormatFlagsNoWrap];

  if toLineLimit in FOptions then
    Result := Result + [StringFormatFlagsLineLimit];

  if toNoClip in FOptions then
    Result := Result + [StringFormatFlagsNoClip];

  if toBypassGDI in FOptions then
    Result := Result + [StringFormatFlagsBypassGDI];
end;

{ TGDITextCollection }

function TGDITextCollection.Add: TGDIText;
begin
  Result := TGDIText(Inherited Add);
end;

function TGDITextCollection.GetItems(Index: Integer): TGDIText;
begin
  Result := TGDIText(Inherited GetItem(Index));
end;

procedure TGDITextCollection.SetItems(Index: Integer; const Value: TGDIText);
begin
  inherited SetItem(Index, Value);
end;

end.
