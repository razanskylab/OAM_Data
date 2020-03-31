% Load_Raw_Data(Pos,filePath) @ Pos
% load raw, unconverted position data from file and also get required info
% stored in scantemp
%
% Johannes Rebling, (johannesrebling@gmail.com), 2018

function Load_Raw_Data(Pos,filePath)
  tic();

  MatFileObject = matfile(filePath);  % does not load the actual data (yet)
  RawFileInfo = whos('-file',filePath); % does not load the actual data!!!
  varNames = {RawFileInfo(:).name}; % get cell array with names

  % get raw position vector ----------------------------------------------------
  varName = 'chNi';
  varIdx = strcmp(varNames,varName);
  if any(varIdx) % found variable with the requestet name in the mat file
    varInfo = RawFileInfo(varIdx);
  else
    error('MatFile does not contain raw data  %s!',varName);
  end
  byteSizeStr = num_to_SI_string(varInfo.bytes);
  Pos.VPrintF('Loading position data (%sB)...',byteSizeStr);
  Pos.xSRaw  = MatFileObject.chNi;

  % get info stored in ScanTemp ------------------------------------------------
  varName = 'Scan';
  varIdx = strcmp(varNames,varName);
  ScanInfo = []; % try and find scan info
  if any(varIdx) % found variable with the requestet name in the mat file
    ScanInfo  = MatFileObject.Scan;
  end
  varName = 'ScanTemp';
  varIdx = strcmp(varNames,varName);
  if any(varIdx)
    ScanInfo  = MatFileObject.ScanTemp;
  end
  if isempty(ScanInfo)
    FSP.Verbose_Warn('Not able to load scan info (Scan or ScanTemp struct missing)!')
  end

  Pos.ctr = ScanInfo.ctr;
  Pos.width = ScanInfo.width;
  Pos.dr = ScanInfo.dr;
  Pos.prf = ScanInfo.prf;
  Pos.bScanRate = 1./ScanInfo.halfPeriod;
  if isfield(ScanInfo.PI,'vel')
     Pos.targetVel(1) = ScanInfo.PI.vel;
  elseif isfield(ScanInfo.PI,'velocity')
      Pos.targetVel(1) = ScanInfo.PI.velocity;
  else
      error('Can not load PI stage velocity!');
  end
  if isfield(ScanInfo.Owis,'vel')
     Pos.targetVel(2) = ScanInfo.Owis.vel;
  elseif isfield(ScanInfo.Owis,'velocity')
      Pos.targetVel(2) = ScanInfo.Owis.velocity;
  else
      error('Can not load PI stage velocity!');
  end
  Pos.ntargetBscans = ScanInfo.nPiezoCycles*2;

  Pos.VPrintF('done (%3.2f s).\n',toc());
end
