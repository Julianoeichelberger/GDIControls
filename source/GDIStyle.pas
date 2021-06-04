unit GDIStyle;

interface

uses
  Classes, Graphics, GDI, GDICtrls;

type
  TGDIStyle = class(TGDIPersistent)
  private
    FControl: TCustomCtrl;
    FColorEnd: TColor;
    FGradientMode: TGPLinearGradientMode;
    FColorBegin: TColor;
    FOpacity: Word;
    FAngle: Word;
    procedure SetColorBegin(const Value: TColor);
    procedure SetColorEnd(const Value: TColor);
    procedure SetGradientMode(const Value: TGPLinearGradientMode);
    procedure SetOpacity(const Value: Word);
    procedure SetAngle(const Value: Word);
  private
    function GPColorBegin: TGPColor;
    function GPColorEnd: TGPColor;
    function GradientBrush: IGPLinearGradientBrush;
  public
    constructor Create(AControl: TCustomCtrl);
    destructor Destroy; override;

    procedure Draw(GPGraphics: IGPGraphics); override;
    procedure Assign(Source: TPersistent); override;
  published
    property Angle: Word read FAngle write SetAngle default 10;
    property ColorBegin: TColor read FColorBegin write SetColorBegin default clGray;
    property ColorEnd: TColor read FColorEnd write SetColorEnd default clBtnFace;
    property GradientMode: TGPLinearGradientMode read FGradientMode write SetGradientMode default LinearGradientModeHorizontal;
    property Opacity: Word read FOpacity write SetOpacity default 255;
  end;

implementation

{ TGDIStyle }

procedure TGDIStyle.Assign(Source: TPersistent);
begin
  if Source is TGDIStyle then
  begin
    Self.FColorEnd := TGDIStyle(Source).ColorEnd;
    Self.FGradientMode := TGDIStyle(Source).GradientMode;
    Self.FColorBegin := TGDIStyle(Source).ColorBegin;
    Self.FOpacity := TGDIStyle(Source).Opacity;
    Self.FAngle := TGDIStyle(Source).Angle;
  end
  else
    inherited;
end;

constructor TGDIStyle.Create(AControl: TCustomCtrl);
begin
  FControl := AControl;
  FAngle := 10;
  FOpacity := 255;
  FColorBegin := clGray;
  FColorEnd := clBtnFace;
  FGradientMode := LinearGradientModeHorizontal;
end;

destructor TGDIStyle.Destroy;
begin
  inherited;
end;

procedure TGDIStyle.Draw(GPGraphics: IGPGraphics);
var
  GPGraphicsPath: IGPGraphicsPath;
begin
  GPGraphicsPath := TGPGraphicsPath.Create;
  GPGraphicsPath.Reset;

  GPGraphicsPath.AddArc(3, 3, FAngle, FAngle, 180, 90);
  GPGraphicsPath.AddArc(FControl.ClientWidth - FAngle - 4, 3, FAngle, FAngle, 270, 90);
  GPGraphicsPath.AddArc(FControl.ClientWidth - FAngle - 4, FControl.ClientHeight - FAngle - 4, FAngle, FAngle, 0, 90);
  GPGraphicsPath.AddArc(3, FControl.ClientHeight - FAngle - 4, FAngle, FAngle, 90, 90);
  GPGraphicsPath.CloseFigure;

  GPGraphics.SmoothingMode := SmoothingModeAntiAlias;
  GPGraphics.TextRenderingHint := TextRenderingHintClearTypeGridFit;
  GPGraphics.FillPath(GradientBrush, GPGraphicsPath);
end;

function TGDIStyle.GPColorBegin: TGPColor;
begin
  Result.InitializeFromColorRef(FColorBegin);
  Result.Alpha := FOpacity;
end;

function TGDIStyle.GPColorEnd: TGPColor;
begin
  Result.InitializeFromColorRef(FColorEnd);
  Result.Alpha := FOpacity;
end;

function TGDIStyle.GradientBrush: IGPLinearGradientBrush;
begin
  Result := TGPLinearGradientBrush.Create(
    TGPRectF.Create(0, 0, FControl.ClientWidth, FControl.ClientHeight), GPColorBegin, GPColorEnd, FGradientMode);
end;

procedure TGDIStyle.SetAngle(const Value: Word);
begin
  if FAngle <> Value then
  begin
    FAngle := Value;
    DoChange(Self);
  end;
end;

procedure TGDIStyle.SetColorBegin(const Value: TColor);
begin
  if FColorBegin <> Value then
  begin
    FColorBegin := Value;
    DoChange(Self);
  end;
end;

procedure TGDIStyle.SetColorEnd(const Value: TColor);
begin
  if FColorEnd <> Value then
  begin
    FColorEnd := Value;
    DoChange(Self);
  end;
end;

procedure TGDIStyle.SetGradientMode(const Value: TGPLinearGradientMode);
begin
  if FGradientMode <> Value then
  begin
    FGradientMode := Value;
    DoChange(Self);
  end;
end;

procedure TGDIStyle.SetOpacity(const Value: Word);
begin
  if (FOpacity <> Value) and (Value in [0 .. 255]) then
  begin
    FOpacity := Value;
    DoChange(Self);
  end;

end;

end.
