unit GDIBadge;

interface

uses
  Classes, Graphics, Winapi.Messages, Winapi.Windows, Vcl.Forms, SysUtils,
  GDI, GDICtrls;

type
  TBadgeAlign = (
    baTopLeft, baTopMiddle, baTopRight,
    baCenterLeft, baCenterMiddle, baCenterRight,
    baBottonLeft, baBottonMiddle, baBottonRight);

  TBadgeTextAlign = (btaInside, btaAbove, btaBellow, btaLeft, btaRight);

  TBadgeFormat = (bfCircle, bfRectangle);

  TOnCustomDrawBadge = procedure(Index: Integer; AGPGraphics: IGPGraphics) of object;

  TBadge = Class(TCollectionItem)
  private const
    MIN_LEN = 23;
  private
    FText: string;
    FAlign: TBadgeAlign;
    FColor: TColor;
    FVisible: Boolean;
    FWidth: Integer;
    FPadding: Integer;
    FFormat: TBadgeFormat;
    FHeight: Integer;
    FTextAlign: TBadgeTextAlign;
    FAutoSize: Boolean;
    FIndentText: Integer;
    FFont: TFont;
    procedure SetVisible(const Value: Boolean);
    procedure SetAlign(const Value: TBadgeAlign);
    procedure SetColor(const Value: TColor);
    procedure SetWidth(const Value: Integer);
    procedure SetText(const Value: string);
    procedure SetPadding(const Value: Integer);
    procedure SetFormat(const Value: TBadgeFormat);
    procedure SetHeight(const Value: Integer);
    procedure SetTextAlign(const Value: TBadgeTextAlign);
    procedure SetFont(const Value: TFont);
    procedure SetAutoSize(const Value: Boolean);
    procedure SetIndentText(const Value: Integer);
  private
    function Control: TCustomCtrl;
    procedure DoChange(Sender: TObject);
    function CanChangeProp(const ACurrentValue, AValue: Integer): Boolean;
    procedure Paint(GPGraphics: IGPGraphics);
  protected
    Function GetDisplayName: String; Override;
  public
    constructor Create(Collection: TCollection); override;
    destructor Destroy; override;

    procedure Assign(Source: TPersistent); override;
  published
    property Align: TBadgeAlign read FAlign write SetAlign default baTopLeft;
    property AutoSize: Boolean read FAutoSize write SetAutoSize default True;
    property Color: TColor read FColor write SetColor default clRed;
    property Font: TFont read FFont write SetFont;
    property Format: TBadgeFormat read FFormat write SetFormat default bfCircle;

    property Text: string read FText write SetText;
    property TextAlign: TBadgeTextAlign read FTextAlign write SetTextAlign default btaInside;

    property Visible: Boolean read FVisible write SetVisible default false;

    property Padding: Integer read FPadding write SetPadding default 5;
    property Height: Integer read FHeight write SetHeight default 0;
    property Width: Integer read FWidth write SetWidth default 0;
    property IndentText: Integer read FIndentText write SetIndentText default 0;
  end;

  TBadgeCollection = Class(TOwnedCollection)
  private
    FOnChange: TNotifyEvent;
    Function GetItems(Index: Integer): TBadge;
    Procedure SetItems(Index: Integer; Const Value: TBadge);
  protected
    procedure Notify(Item: TCollectionItem; Action: TCollectionNotification); override;
  public
    function Control: TCustomCtrl;
    function Add: TBadge;

    procedure Paint(GPGraphics: IGPGraphics);
    procedure DoChangeAll;

    property OnChange: TNotifyEvent read FOnChange write FOnChange;
    Property Items[Index: Integer]: TBadge Read GetItems Write SetItems;
  end;

implementation


{ TBadge }

uses
  Math, GDIUtils;

procedure TBadge.Assign(Source: TPersistent);
begin
  if Source is TBadge then
  begin
    Self.FVisible := TBadge(Source).Visible;
    Self.FColor := TBadge(Source).Color;
    Self.FHeight := TBadge(Source).Height;
    Self.FAlign := TBadge(Source).Align;
    Self.FText := TBadge(Source).Text;
    Self.FWidth := TBadge(Source).Width;
    Self.FPadding := TBadge(Source).Padding;
    Self.FAutoSize := TBadge(Source).AutoSize;
  end
  else
    inherited;
end;

function TBadge.CanChangeProp(const ACurrentValue, AValue: Integer): Boolean;
begin
  Result := (ACurrentValue <> AValue) and
    ((FAutoSize and (AValue = 0)) or (not FAutoSize and (AValue > 0)));
end;

function TBadge.Control: TCustomCtrl;
begin
  Result := TBadgeCollection(Collection).Control;
end;

constructor TBadge.Create(Collection: TCollection);
begin
  inherited;
  FAutoSize := True;
  FVisible := false;
  FColor := clRed;
  FAlign := baTopLeft;
  FPadding := 5;
  FFormat := bfCircle;
  FHeight := 0;
  FWidth := 0;
  FIndentText := 0;
  FFont := TFont.Create;
  FFont.OnChange := DoChange;
end;

destructor TBadge.Destroy;
begin
  FFont.Free;
  inherited;
end;

procedure TBadge.DoChange(Sender: TObject);
begin
  if Assigned(TBadgeCollection(Collection).FOnChange) then
    TBadgeCollection(Collection).OnChange(Sender);
end;

procedure TBadge.Paint(GPGraphics: IGPGraphics);
var
  TextRectF: TGPRectF;
  GdiFont: IGPFont;
  BadgeW, BadgeH, FillX, FillY: Single;
  Colr: TGPColor;

  function CalcPieY: Single;
  begin
    case FAlign of
      baTopLeft, baTopMiddle, baTopRight:
        Result := FPadding;
      baCenterLeft, baCenterMiddle, baCenterRight:
        Result := Control.ClientHeight div 2 - (BadgeW / 2);
    else
      Result := Control.ClientHeight - BadgeW - FPadding;
    end;
  end;

  function CalcPieX: Single;
  begin
    case FAlign of
      baTopLeft, baCenterLeft, baBottonLeft:
        Result := FPadding;
      baTopMiddle, baCenterMiddle, baBottonMiddle:
        Result := (Control.ClientWidth div 2) - (BadgeW / 2);
    else
      Result := Control.ClientWidth - BadgeW - FPadding;
    end;
  end;

  function CalcTextPoint(X, Y: Single): TGPPointF;
  var
    TextX, TextY: Single;
  begin
    case FTextAlign of
      btaAbove:
        begin
          TextY := Y - TextRectF.Height - FIndentText;
          TextX := X;
        end;
      btaBellow:
        begin
          TextY := Y + BadgeW + FIndentText;
          TextX := X;
        end;
      btaLeft:
        begin
          TextY := Y + ((BadgeW - TextRectF.Height) / 2);
          TextX := X - TextRectF.Width - FIndentText;
        end;
      btaRight:
        begin
          TextY := Y + ((BadgeW - TextRectF.Height) / 2);
          TextX := X + TextRectF.Width + FIndentText;
        end;
    else
      TextY := Y + ((BadgeW - TextRectF.Height) / 2);
      TextX := X;
    end;
    Result := TGPPointF.Create(TextX, TextY);
  end;

begin
  GdiFont := TGPFont.CreateByFont(Control.Canvas.Handle, FFont);

  TextRectF := GPGraphics.MeasureString(FText, GdiFont, TGPRectF.Create(0, 0, Control.Width, Control.Height));

  BadgeW := FWidth;
  BadgeH := FHeight;
  if FAutoSize then
  begin
    BadgeW := IfThen(TextRectF.Width < MIN_LEN, MIN_LEN, TextRectF.Width);
    BadgeH := IfThen(TextRectF.Height < MIN_LEN, MIN_LEN, TextRectF.Height);
  end;

  Colr := TGPColor.CreateFromColorRef(FColor);
  Colr.Alpha := 200;

  FillX := CalcPieX;
  FillY := CalcPieY;

  if FFormat = bfCircle then

    GPGraphics.FillPie(TGPSolidBrush.Create(Colr), FillX, FillY, BadgeW, BadgeW, 0, 360)
  else
    GPGraphics.FillRectangle(TGPSolidBrush.Create(Colr), FillX, FillY, BadgeW, BadgeH);

  GPGraphics.DrawString(FText, GdiFont, CalcTextPoint(FillX, FillY),
    TGPSolidBrush.Create(TGPColor.CreateFromColorRef(FFont.Color)));
end;

function TBadge.GetDisplayName: String;
begin
  If FText <> '' Then
    Result := FText
  Else
    Inherited GetDisplayName;
end;

procedure TBadge.SetAlign(const Value: TBadgeAlign);
begin
  if FAlign <> Value then
  begin
    FAlign := Value;
    DoChange(Self);
  end;
end;

procedure TBadge.SetAutoSize(const Value: Boolean);
begin
  if FAutoSize <> Value then
  begin
    FAutoSize := Value;
    if FAutoSize then
    begin
      FWidth := 0;
      FHeight := 0;
    end
    else
    begin
      if FHeight = 0 then
        FHeight := MIN_LEN;
      if FWidth = 0 then
        FWidth := MIN_LEN;
    end;
    DoChange(Self);
  end;
end;

procedure TBadge.SetColor(const Value: TColor);
begin
  if FColor <> Value then
  begin
    FColor := Value;
    DoChange(Self);
  end;
end;

procedure TBadge.SetFont(const Value: TFont);
begin
  if FFont <> Value then
  begin
    FFont.Assign(Value);
    DoChange(Self);
  end;
end;

procedure TBadge.SetFormat(const Value: TBadgeFormat);
begin
  if FFormat <> Value then
  begin
    FFormat := Value;
    DoChange(Self);
  end;
end;

procedure TBadge.SetHeight(const Value: Integer);
begin
  if CanChangeProp(FHeight, Value) then
  begin
    FHeight := Value;
    if FFormat = bfCircle then
      FWidth := Value;
    DoChange(Self);
  end;
end;

procedure TBadge.SetIndentText(const Value: Integer);
begin
  if FIndentText <> Value then
  begin
    FIndentText := Value;
    DoChange(Self);
  end;
end;

procedure TBadge.SetPadding(const Value: Integer);
begin
  if FPadding <> Value then
  begin
    FPadding := Value;
    DoChange(Self);
  end;
end;

procedure TBadge.SetText(const Value: string);
begin
  if FText <> Value then
  begin
    FText := Value;
    DoChange(Self);
  end;
end;

procedure TBadge.SetTextAlign(const Value: TBadgeTextAlign);
begin
  if FTextAlign <> Value then
  begin
    FTextAlign := Value;
    DoChange(Self);
  end;
end;

procedure TBadge.SetVisible(const Value: Boolean);
begin
  if FVisible <> Value then
  begin
    FVisible := Value;
    DoChange(Self);
  end;
end;

procedure TBadge.SetWidth(const Value: Integer);
begin
  if CanChangeProp(FWidth, Value) then
  begin
    FWidth := Value;
    if FFormat = bfCircle then
      FHeight := Value;
    DoChange(Self);
  end;
end;

{ TBadgeCollection }

function TBadgeCollection.Add: TBadge;
begin
  Result := TBadge(Inherited Add);
end;

function TBadgeCollection.Control: TCustomCtrl;
begin
  Result := TCustomCtrl(GetOwner);
end;

procedure TBadgeCollection.DoChangeAll;
var
  I: Integer;
begin
  for I := 0 to Pred(Self.Count) do
    if Self.Items[I].Visible then
      Self.Items[I].DoChange(Self.Items[I]);
end;

function TBadgeCollection.GetItems(Index: Integer): TBadge;
begin
  Result := TBadge(Inherited GetItem(Index));
end;

procedure TBadgeCollection.Notify(Item: TCollectionItem; Action: TCollectionNotification);
begin
  inherited;
  if Action = cnDeleting then
    DoChangeAll;
end;

procedure TBadgeCollection.Paint(GPGraphics: IGPGraphics);
var
  I: Integer;
begin
  for I := 0 to Pred(Self.Count) do
    if Self.Items[I].Visible then
      Self.Items[I].Paint(GPGraphics);
end;

procedure TBadgeCollection.SetItems(Index: Integer; const Value: TBadge);
begin
  inherited SetItem(Index, Value);
end;

end.
