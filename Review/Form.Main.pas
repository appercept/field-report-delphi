unit Form.Main;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, FMX.Objects,
  AWS.SQS, FMX.Memo.Types, FMX.Controls.Presentation, FMX.ScrollBox, FMX.Memo,
  FMX.StdCtrls, System.Actions, FMX.ActnList, System.SyncObjs;

type
  TMainForm = class(TForm)
    ReviewImage: TImage;
    NotesMemo: TMemo;
    CountDownLabel: TLabel;
    CountDownTimer: TTimer;
    ActionList1: TActionList;
    ArchiveAction: TAction;
    DiscardAction: TAction;
    DiscardButton: TButton;
    ApproveButton: TButton;
    procedure FormShow(Sender: TObject);
    procedure CountDownTimerTimer(Sender: TObject);
    procedure DiscardActionExecute(Sender: TObject);
    procedure ArchiveActionExecute(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
  private
    { Private declarations }
    FOptions: ISQSOptions;
    FClient: ISQSClient;
    FCurrentMessage: ISQSMessage;
    FCurrentMessageKey: string;
    FMessageExpiresAt: TDateTime;
    FClosing: Boolean;
    FReadyEvent: TEvent;
    FShutdownEvent: TEvent;
    function GetOptions: ISQSOptions;
    function GetClient: ISQSClient;
    procedure SetCurrentMessage(const Value: ISQSMessage);
    procedure LoadImageFrom(const ARegion, ABucket, AKey: string);
    procedure NextMessage;
    property Closing: Boolean read FClosing;
    property Options: ISQSOptions read GetOptions;
    property Client: ISQSClient read GetClient;
    property CurrentMessage: ISQSMessage read FCurrentMessage write SetCurrentMessage;
    property CurrentMessageKey: string read FCurrentMessageKey;
    property MessageExpiresAt: TDateTime read FMessageExpiresAt;
    property ReadyEvent: TEvent read FReadyEvent;
    property ShutdownEvent: TEvent read FShutdownEvent;
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

procedure TMainForm.ArchiveActionExecute(Sender: TObject);
var
  LJSON: TJSONObject;
begin
  LJSON := TJSONObject.Create;
  try
    LJSON.AddPair('key', CurrentMessageKey);
    if Client.SendMessage(ArchiveQueue, LJSON.ToString).IsSuccessful then
    begin
      Client.DeleteMessage(NewReportQueue, CurrentMessage.ReceiptHandle);
      NextMessage;
    end;
  finally
    LJSON.Free;
  end;
end;

procedure TMainForm.CountDownTimerTimer(Sender: TObject);
var
  LSecondsRemaining: Integer;
begin
  LSecondsRemaining := SecondsBetween(Now, MessageExpiresAt);
  if LSecondsRemaining = 0 then
  begin
      NextMessage;
      Exit;
  end;

  if LSecondsRemaining > 0 then
    CountDownLabel.Text := Format('%d seconds remaining', [LSecondsRemaining]);
end;

procedure TMainForm.DiscardActionExecute(Sender: TObject);
begin
  Client.DeleteMessage(NewReportQueue, CurrentMessage.ReceiptHandle);
  NextMessage;
end;

procedure TMainForm.FormCreate(Sender: TObject);
begin
  FReadyEvent := TEvent.Create;
  FShutdownEvent := TEvent.Create;
end;

procedure TMainForm.FormDestroy(Sender: TObject);
begin
  FClosing := True;
  CurrentMessage := nil;
  Application.ProcessMessages;
  ReadyEvent.SetEvent;
  ShutdownEvent.WaitFor;
  FShutdownEvent.Free;
  FReadyEvent.Free;
end;

procedure TMainForm.FormShow(Sender: TObject);
var
  LPoller: ISQSQueuePoller;
begin
  LPoller := TSQSQueuePoller.Create(NewReportQueue, Client);
  LPoller.MaxNumberOfMessages := 1;
  LPoller.SkipDelete := True;
  LPoller.OnBeforeRequest := procedure(const APoller: ISQSQueuePoller;
                                       const AStats: TSQSQueuePollerStatistics)
  begin
    if AStats.RequestCount = 0 then
      Exit;

    if not Closing then
      ReadyEvent.WaitFor(30000);

    if Closing then
      APoller.StopPolling;
  end;

  TTask.Run(
    procedure
    begin
      LPoller.Poll(
        procedure(const AMessages: TSQSMessages)
        begin
          if AMessages.Count = 0 then
            Exit;

          TThread.Synchronize(nil,
            procedure
            begin
              CurrentMessage := AMessages.First;
            end
          );
        end
      );
      ShutDownEvent.SetEvent;
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
    FOptions.Region := AwsRegion;
  end;

  Result := FOptions;
end;

procedure TMainForm.LoadImageFrom(const ARegion, ABucket, AKey: string);
var
  LS3Options: IS3Options;
  LS3: IS3Client;
  LGetObjectResponse: IS3GetObjectResponse;
  LGetObjectTaggingResponse: IS3GetObjectTaggingResponse;
  LKey: string;
begin
  LKey := TNetEncoding.URL.Decode(AKey);
  LS3Options := TS3Options.Create;
  LS3Options.Region := ARegion;
  LS3 := TS3Client.Create(LS3Options);
  try
    LGetObjectResponse := LS3.GetObject(ABucket, LKey);
    ReviewImage.Bitmap.LoadFromStream(LGetObjectResponse.Body);
    LGetObjectTaggingResponse := LS3.GetObjectTagging(ABucket, LKey);
    NotesMemo.Text := LGetObjectTaggingResponse.Tagging.TagSet.Values['Notes'];
    FCurrentMessageKey := AKey;
  except
    on E: ES3Exception do
      NotesMemo.Text := Format('Error fetching image for review: %s', [E.Message]);
  end;
end;

procedure TMainForm.NextMessage;
begin
  CurrentMessage := nil;
  ReadyEvent.SetEvent;
end;

procedure TMainForm.SetCurrentMessage(const Value: ISQSMessage);
var
  LMessageJSON, LNotificationJSON: TJSONObject;
  LNotification, LRegion, LBucket, LKey: string;
begin
  FMessageExpiresAt := IncSecond(Now, 30);
  FCurrentMessage := Value;
  if Assigned(FCurrentMessage) then
  begin
    ReadyEvent.ResetEvent;
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
    ArchiveAction.Enabled := True;
    DiscardAction.Enabled := True;
  end
  else
  begin
    CountDownTimer.Enabled := False;
    if Closing then
      CountDownLabel.Text := 'Shutting down...'
    else
      CountDownLabel.Text := 'Waiting...';
    FCurrentMessageKey := '';
    FMessageExpiresAt := 0;
    ArchiveAction.Enabled := False;
    DiscardAction.Enabled := False;
    NotesMemo.Text := '';
    ReviewImage.Bitmap.Clear(MainForm.Fill.Color);
  end;
end;

end.
