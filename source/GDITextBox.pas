unit GDITextBox;

interface

uses
  Vcl.Controls, Vcl.Graphics, Winapi.Messages, Winapi.Windows, Vcl.Forms, System.Classes, System.SysUtils, System.Math,
  Winapi.ActiveX, GDI, GDICtrls, GDIText;

type
  TTextBoxAlign = (tbaBottom, tbaCenter, tbaTop);

  TGDITextBox = class(TGDIPersistent)
  private
    FControl: TCustomCtrl;
    FAlign: TTextBoxAlign;
    FColor: TColor;
    FFont: TFont;
    FParentColor: Boolean;
    FText: string;
    FPadding: Integer;
    FOpacity: Word;
    procedure SetAlign(const Value: TTextBoxAlign);
    procedure SetColor(const Value: TColor);
    procedure SetFont(const Value: TFont);
    procedure SetParentColor(const Value: Boolean);
    procedure SetText(const Value: string);
    procedure SetPadding(const Value: Integer);
    procedure SetOpacity(const Value: Word);
  public
    constructor Create(AControl: TCustomCtrl);
    destructor Destroy; override;

    procedure Draw(GPGraphics: IGPGraphics); override;
    procedure Assign(Source: TPersistent); override;
  published
    property Align: TTextBoxAlign read FAlign write SetAlign default tbaBottom;
    property Color: TColor read FColor write SetColor default clDefault;
    property Font: TFont read FFont write SetFont;
    property ParentColor: Boolean read FParentColor write SetParentColor default True;
    property Text: string read FText write SetText;
    property Padding: Integer read FPadding write SetPadding default 0;
    property Opacity: Word read FOpacity write SetOpacity default 200;
  end;

implementation


uses
  GDIUtils;

{ TGDITextBox }

procedure TGDITextBox.Assign(Source: TPersistent);
begin
  if Source is TGDITextBox then
  begin
    Self.FColor := TGDITextBox(Source).Color;
    Self.FParentColor := TGDITextBox(Source).ParentColor;
    Self.FAlign := TGDITextBox(Source).Align;
    Self.FPadding := TGDITextBox(Source).Padding;
    Self.FText := TGDITextBox(Source).Text;
    Self.FOpacity := TGDITextBox(Source).Opacity;
  end
  else
    inherited;
end;

constructor TGDITextBox.Create(AControl: TCustomCtrl);
begin
  FControl := AControl;
  FFont := TFont.Create;
  FAlign := tbaBottom;
  FParentColor := True;
  FColor := clDefault;
  FOpacity := 200;
  FPadding := 0;
end;

destructor TGDITextBox.Destroy;
begin
  FFont.Free;
  inherited;
end;

procedure TGDITextBox.Draw(GPGraphics: IGPGraphics);
var
  GPGraphicsPath: IGPGraphicsPath;
  Fontx: IGPFont;
  Rectf: TGPRectF;
  StringFormat: IGPStringFormat;
  Pointx: TGPPointF;
begin
  if FText.IsEmpty then
    exit;

  Fontx := FFont.toGPFont(FControl.Canvas.Handle);
  Rectf := GPGraphics.MeasureString(FText, Fontx, TGPRectF.Create(0, 0, FControl.Width, FControl.Height));

  if not FParentColor then
  begin
    GPGraphicsPath := TGPGraphicsPath.Create;
    GPGraphicsPath.Reset;

    case FAlign of
      tbaBottom:
        GPGraphicsPath.AddRectangle(TGPRectF.Create(
          FPadding,
          FControl.ClientHeight - (Rectf.Height + 10),
          FControl.ClientWidth - (FPadding * 2),
          Rectf.Height + 10)
          );
      tbaCenter:
        GPGraphicsPath.AddRectangle(TGPRectF.Create(FPadding,
          (FControl.ClientHeight / 2) - ((Rectf.Height + 10) / 2),
          FControl.ClientWidth - (FPadding * 2),
          Rectf.Height + 10)
          );
      tbaTop:
        GPGraphicsPath.AddRectangle(TGPRectF.Create(FPadding,
          0,
          FControl.ClientWidth - (FPadding * 2),
          Rectf.Height + 10)
          );
    end;
    GPGraphicsPath.CloseFigure;
    GPGraphics.FillPath(TGPSolidBrush.Create(ColorToGPColor(FColor, FOpacity)), GPGraphicsPath);
  end;
  StringFormat := TGPStringFormat.GenericDefault;
  StringFormat.Alignment := StringAlignmentCenter;
  StringFormat.Trimming := StringTrimmingEllipsisPath;

  case FAlign of
    tbaBottom:
      GPGraphics.DrawString(FText, Fontx,
        TGPRectF.Create(TGPPointF.Create(0, (FControl.ClientHeight - (Rectf.Height + 5))),
        TGPSizeF.Create(FControl.ClientWidth, FControl.ClientHeight - (FControl.ClientHeight - (Rectf.Height + 5)))),
        StringFormat, TGPSolidBrush.Create(TGPColor.CreateFromColorRef(FFont.Color)));
    tbaCenter:
      begin
        Pointx.X := 0;
        Pointx.Y := ((FControl.Height) / 2) - (Rectf.Height / 2);
        GPGraphics.DrawString(FText, Fontx, TGPRectF.Create(Pointx, TGPSizeF.Create(FControl.ClientWidth,
          FControl.ClientHeight - Pointx.Y)), StringFormat, TGPSolidBrush.Create(TGPColor.CreateFromColorRef(FFont.Color)));
      end;
    tbaTop:
      begin
        GPGraphics.DrawString(FText, Fontx,
          TGPRectF.Create(TGPPointF.Create(0, 5),
          TGPSizeF.Create(FControl.ClientWidth, FControl.ClientHeight - (FControl.ClientHeight - (Rectf.Height + 5)))),
          StringFormat, TGPSolidBrush.Create(TGPColor.CreateFromColorRef(FFont.Color)));
      end;
  end;
end;

procedure TGDITextBox.SetAlign(const Value: TTextBoxAlign);
begin
  if FAlign <> Value then
  begin
    FAlign := Value;
    DoChange(Self);
  end;
end;

procedure TGDITextBox.SetColor(const Value: TColor);
begin
  if FColor <> Value then
  begin
    FColor := Value;
    DoChange(Self);
  end;
end;

procedure TGDITextBox.SetFont(const Value: TFont);
begin
  FFont.Assign(Value);
end;

procedure TGDITextBox.SetOpacity(const Value: Word);
begin
  if (FOpacity <> Value) and (Value in [0 .. 255]) then
  begin
    FOpacity := Value;
    DoChange(Self);
  end;
end;

procedure TGDITextBox.SetPadding(const Value: Integer);
begin
  if FPadding <> Value then
  begin
    FPadding := Value;
    DoChange(Self);
  end;
end;

procedure TGDITextBox.SetParentColor(const Value: Boolean);
begin
  if FParentColor <> Value then
  begin
    FParentColor := Value;
    DoChange(Self);
  end;
end;

procedure TGDITextBox.SetText(const Value: string);
begin
  if FText <> Value then
  begin
    FText := Value;
    DoChange(Self);
  end;
end;

end.
