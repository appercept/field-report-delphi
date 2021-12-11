program Archive;

{$APPTYPE CONSOLE}

{$R *.res}

uses
  AWS.Core,
  AWS.S3,
  AWS.SQS,
  Settings in 'Settings.pas',
  System.SysUtils,
  System.JSON;

var
  Options: IAWSOptions;
  SQSOptions: ISQSOptions;
  SQSClient: ISQSClient;
  QueuePoller: ISQSQueuePoller;

const
  LOG_DATE_FORMAT = 'yyyymmdd''T''hhnnss';

procedure Log(const AMessage: string; ANewLine: Boolean = True);
begin
  if ANewLine then
    Writeln(Format('[%s] %s', [FormatDateTime(LOG_DATE_FORMAT, Now), AMessage]))
  else
    Write(Format('[%s] %s', [FormatDateTime(LOG_DATE_FORMAT, Now), AMessage]));
end;

procedure ArchiveReport(const AReportKey: string);
var
  LS3Options: IS3Options;
  LS3Client: IS3Client;
  LRequest: IS3CopyObjectRequest;
  LResponse: IS3CopyObjectResponse;
begin
  Log(Format('Archiving report ''%s''...', [AReportKey]), False);
  LS3Options := TS3Options.Create(Options);
  LS3Client := TS3Client.Create(LS3Options);
  LRequest := TS3CopyObjectRequest.Create(
    ArchiveReportsBucketName,
    Format('%s/%s', [InboundReportsBucketName, AReportKey]),
    AReportKey
  );
  try
    LResponse := LS3Client.CopyObject(LRequest);
    if LResponse.IsSuccessful then
      Writeln('done.');
  except
    on E: ES3Exception do
    begin
      Writeln('error:');
      Log(E.Message);
    end;
  end;
end;

procedure ProcessArchiveRequest(const AMessage: ISQSMessage);
var
  LJSON: TJSONObject;
  LReportKey: string;
begin
  LJSON := TJSONObject.ParseJSONValue(AMessage.Body) as TJSONObject;
  if LJSON.TryGetValue<string>('key', LReportKey) then
    ArchiveReport(LReportKey);
end;

begin
  try
    // Initialize common options.
    Options := TAWSOptions.Create;
    Options.AccessKeyId := AccessKeyId;
    Options.SecretAccessKey := SecretAccessKey;
    Options.Region := AwsRegion;

    SQSOptions := TSQSOptions.Create(Options);
    SQSClient := TSQSClient.Create(SQSOptions);
    QueuePoller := TSQSQueuePoller.Create(ArchiveQueue, SQSClient);

    Log('Waiting for archive report requests...');
    QueuePoller.Poll(
      procedure(const AMessages: TSQSMessages)
      var
        LMessage: ISQSMessage;
      begin
        for LMessage in AMessages do
          ProcessArchiveRequest(LMessage);
      end
    );
  except
    on E: Exception do
      Writeln(E.ClassName, ': ', E.Message);
  end;
end.
