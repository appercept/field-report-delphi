program FieldReport;

uses
  System.StartUpCopy,
  FMX.Forms,
  Form.Main in 'Form.Main.pas' {HeaderFooterForm};

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(THeaderFooterForm, HeaderFooterForm);
  Application.Run;
end.
