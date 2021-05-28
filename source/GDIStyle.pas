unit GDIStyle;

interface

uses
  Classes, Graphics, GDI;

type
  TGDIStyle = class(TPersistent)
  private
    FOnChange: TNotifyEvent;
    FColorEnd: TColor;
    FGradientMode: TGPLinearGradientMode;
    FColorBegin: TColor;
    FOpacity: Word;
    procedure SetColorBegin(const Value: TColor);
    procedure SetColorEnd(const Value: TColor);
    procedure SetGradientMode(const Value: TGPLinearGradientMode);
    procedure DoChange;
    procedure SetOpacity(const Value: Word);
  public
    constructor Create;
    destructor Destroy; override;

    procedure Assign(Source: TPersistent); override;
    property OnChange: TNotifyEvent read FOnChange write FOnChange;
  published
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
  end
  else
    inherited;
end;

constructor TGDIStyle.Create;
begin
  FOpacity := 255;
  FColorBegin := clGray;
  FColorEnd := clBtnFace;
  FGradientMode := LinearGradientModeHorizontal;
end;

destructor TGDIStyle.Destroy;
begin
  inherited;
end;

procedure TGDIStyle.DoChange;
begin
  if Assigned(FOnChange) then
    OnChange(Self);
end;

procedure TGDIStyle.SetColorBegin(const Value: TColor);
begin
  if FColorBegin <> Value then
  begin
    FColorBegin := Value;
    DoChange;
  end;
end;

procedure TGDIStyle.SetColorEnd(const Value: TColor);
begin
  if FColorEnd <> Value then
  begin
    FColorEnd := Value;
    DoChange;
  end;
end;

procedure TGDIStyle.SetGradientMode(const Value: TGPLinearGradientMode);
begin
  if FGradientMode <> Value then
  begin
    FGradientMode := Value;
    DoChange;
  end;
end;

procedure TGDIStyle.SetOpacity(const Value: Word);
begin
  if (FOpacity <> Value) and (Value in [0 .. 255]) then
  begin
    FOpacity := Value;
    DoChange;
  end;

end;

end.
