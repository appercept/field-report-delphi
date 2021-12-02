unit Frame.ReportItem;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants, 
  FMX.Types, FMX.Graphics, FMX.Controls, FMX.Forms, FMX.Dialogs, FMX.StdCtrls,
  FMX.Objects, FMX.Controls.Presentation;

type
  TReportItemFrame = class(TFrame)
    ThumbnailImage: TImage;
    NotesLabel: TLabel;
    UploadProgressBar: TProgressBar;
  private
    { Private declarations }
    FReportKey: string;
    function GetReportKey: string;
  public
    { Public declarations }
    procedure UploadReport(const APicture: TBitmap; const AReport: string);
    property ReportKey: string read GetReportKey;
  end;

implementation

uses
  AWS.S3,
  Settings,
  System.Threading;

{$R *.fmx}

{ TReportItemFrame }

function TReportItemFrame.GetReportKey: string;
var
  LGUID: TGUID;
  LGUIDString: string;
begin
  if FReportKey.IsEmpty then
  begin
    CreateGUID(LGUID);
    LGUIDString := Format(
      '%0.8X-%0.4X-%0.4X-%0.2X%0.2X-%0.2X%0.2X%0.2X%0.2X%0.2X%0.2X',
      [
        LGUID.D1,
        LGUID.D2,
        LGUID.D3,
        LGUID.D4[0],
        LGUID.D4[1],
        LGUID.D4[2],
        LGUID.D4[3],
        LGUID.D4[4],
        LGUID.D4[5],
        LGUID.D4[6],
        LGUID.D4[7]
      ]
    );
    FReportKey := Format('%s.png', [LGUIDString]);
  end;

  Result := FReportKey;
end;

procedure TReportItemFrame.UploadReport(const APicture: TBitmap;
  const AReport: string);
var
  LStream: TMemoryStream;
  LOptions: IS3Options;
  LS3: IS3Client;
  LRequest: IS3PutObjectRequest;
begin
  ThumbnailImage.Bitmap.Assign(APicture);
  NotesLabel.Text := AReport;
  TTask.Run(
    procedure
    begin
      LStream := TMemoryStream.Create;
      try
        APicture.SaveToStream(LStream);
        LStream.Seek(0, soBeginning);
        LOptions := TS3Options.Create;
        LOptions.AccessKeyId := AccessKeyId;
        LOptions.SecretAccessKey := SecretAccessKey;
        LOptions.Region := AwsRegion;
        LS3 := TS3Client.Create(LOptions);
        LRequest := TS3PutObjectRequest.Create(InboundReportsBucketName, ReportKey, LStream);
        LRequest.ContentType := 'image/png';
        LRequest.Tags.AddTag('Notes', AReport);
        LRequest.OnSendData := procedure(const AContentLength: Int64; AWriteCount: Int64; var AAbort: Boolean)
        begin
          TThread.Queue(nil,
            procedure
            begin
              UploadProgressBar.Max := AContentLength;
              UploadProgressBar.Value := AWriteCount;
            end
          );
        end;
        LS3.PutObject(LRequest);
      finally
        LStream.Free;
      end;
    end
  );
end;

end.
