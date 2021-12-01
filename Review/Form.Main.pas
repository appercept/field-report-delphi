unit Form.Main;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, FMX.Objects,
  AWS.SQS, FMX.Memo.Types, FMX.Controls.Presentation, FMX.ScrollBox, FMX.Memo,
  FMX.StdCtrls;

type
  TMainForm = class(TForm)
    ReviewImage: TImage;
    Memo1: TMemo;
    CountDownLabel: TLabel;
    CountDownTimer: TTimer;
    procedure FormShow(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure CountDownTimerTimer(Sender: TObject);
  private
    { Private declarations }
    FOptions: ISQSOptions;
    FClient: ISQSClient;
    FCurrentMessage: ISQSMessage;
    FMessageExpiresAt: TDateTime;
    FClosing: Boolean;
    function GetOptions: ISQSOptions;
    function GetClient: ISQSClient;
    procedure SetCurrentMessage(const Value: ISQSMessage);
    procedure LoadImageFrom(const ARegion, ABucket, AKey: string);
    property Options: ISQSOptions read GetOptions;
    property Client: ISQSClient read GetClient;
    property CurrentMessage: ISQSMessage read FCurrentMessage write SetCurrentMessage;
    property MessageExpiresAt: TDateTime read FMessageExpiresAt;
  public
    { Public declarations }
  end;

var
  MainForm: TMainForm;

implementation

uses
  AWS.S3,
  Settings,
  System.DateUtils,
  System.JSON,
  System.NetEncoding,
  System.Threading;

{$R *.fmx}

procedure TMainForm.CountDownTimerTimer(Sender: TObject);
var
  LSecondsRemaining: Integer;
begin
  LSecondsRemaining := SecondsBetween(Now, MessageExpiresAt);
  if LSecondsRemaining > 0 then
    CountDownLabel.Text := Format('%d seconds remaining', [LSecondsRemaining])
  else
  begin
    CountDownLabel.Text := 'Waiting...';
    CountDownTimer.Enabled := False;
  end;
end;

procedure TMainForm.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  FClosing := True;
end;

procedure TMainForm.FormShow(Sender: TObject);
var
  LPoller: ISQSQueuePoller;
begin
  LPoller := TSQSQueuePoller.Create(QUEUE_URL, Client);
  LPoller.MaxNumberOfMessages := 1;
  LPoller.SkipDelete := True;
  TTask.Run(
    procedure
    begin
      LPoller.Poll(
        procedure(const AMessages: TSQSMessages)
        begin
          TThread.Synchronize(nil,
            procedure
            begin
              if AMessages.Count > 0 then
                CurrentMessage := AMessages.First;
            end
          );
          if AMessages.Count > 0 then
            Sleep(30000);
          if FClosing then
            LPoller.StopPolling;
        end
      );
    end
  );
end;

function TMainForm.GetClient: ISQSClient;
begin
  if not Assigned(FClient) then
    FClient := TSQSClient.Create(Options);

  Result := FClient;
end;

function TMainForm.GetOptions: ISQSOptions;
begin
  if not Assigned(FOptions) then
  begin
    FOptions := TSQSOptions.Create;
    FOptions.Region := REGION;
  end;

  Result := FOptions;
end;

procedure TMainForm.LoadImageFrom(const ARegion, ABucket, AKey: string);
var
  LS3Options: IS3Options;
  LS3: IS3Client;
  LResponse: IS3GetObjectResponse;
  LKey: string;
begin
  LKey := TNetEncoding.URL.Decode(AKey);
  Memo1.Lines.Add(Format('Loading image from s3://%s/%s (%s)', [ABucket, LKey, ARegion]));
  LS3Options := TS3Options.Create;
  LS3Options.Region := ARegion;
  LS3 := TS3Client.Create(LS3Options);
  try
    LResponse := LS3.GetObject(ABucket, LKey);
    ReviewImage.Bitmap.LoadFromStream(LResponse.Body);
  except
    on E: ES3Exception do
      Memo1.Lines.Add(Format('Error fetching image for review: %s', [E.Message]));
  end;
end;

procedure TMainForm.SetCurrentMessage(const Value: ISQSMessage);
var
  LMessageJSON, LNotificationJSON: TJSONObject;
  LNotification, LRegion, LBucket, LKey: string;
begin
  FMessageExpiresAt := IncSecond(Now, 30);
  FCurrentMessage := Value;
  CountDownTimer.Enabled := True;

  LMessageJSON := TJSONObject.ParseJSONValue(CurrentMessage.Body) as TJSONObject;
  try
    LNotification := LMessageJSON.GetValue<string>('Message');
    LNotificationJSON := TJSONObject.ParseJSONValue(LNotification) as TJSONObject;
    try
      LNotificationJSON.TryGetValue<string>('Records[0].awsRegion', LRegion);
      LNotificationJSON.TryGetValue<string>('Records[0].s3.bucket.name', LBucket);
      LNotificationJSON.TryGetValue<string>('Records[0].s3.object.key', LKey);
      LoadImageFrom(LRegion, LBucket, LKey);
    finally
      LNotificationJSON.Free;
    end;
  finally
    LMessageJSON.Free;
  end;
end;

end.
