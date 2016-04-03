(*
  Copyright 2015, MARS - REST Library

  Home: https://github.com/MARS-library

  ### ### ### ###
  MARS-Curiosity edition
  Home: https://github.com/andrea-magni/MARS

*)
program MARSTemplateClient;

uses
  System.StartUpCopy,
  FMX.Forms,
  FMXClient.Forms.Main in 'FMXClient.Forms.Main.pas' {MainForm},
  FMXClient.DataModules.Main in 'FMXClient.DataModules.Main.pas' {MainDataModule: TDataModule};

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TMainDataModule, MainDataModule);
  Application.CreateForm(TMainForm, MainForm);
  Application.Run;
end.