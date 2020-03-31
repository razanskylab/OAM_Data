% Load_Data(SDO) @ SDO
% load raw data file, only works for modern files, we can no longer support those
% filthy legacy files...
% this is for (partial) loading of large raw data files or variables stored in raw
% data files
% loaded data is stored in SDO.raw and can't be bigger than 2D (for now?)
%
% Exaple:
% SDO.Load_Raw_Data('C:\rawData.mat','superCoolVariable')
%
% Johannes Rebling, (johannesrebling@gmail.com), 2018

function [] = Load_Raw_Data(SDO,filePath,varName)
  % filePath - path to mat file containing 2d shotData of form nSamples x nShots
  % varName under which shotData is stored
  tic();
  SDO.Sync_Subclass_Settings(); % be safe, update the subclass outputs

  % get info on data stored in mat file
  MatFileObject = matfile(filePath);  % does not load the actual data (yet)
  RawFileInfo = whos('-file',filePath); % does not load the actual data!!!

  varNames = {RawFileInfo(:).name}; % get cell array with names
  varIdx = strcmp(varNames,varName);
  if any(varIdx) % found variable with the requestet name in the mat file
    varInfo = RawFileInfo(varIdx);
  else
    error('MatFile does not contain requested variable!');
  end

  nshots = varInfo.size(1);

  if ~SDO.rawDataIsCached
    % load full or cropped data?
    [nSamples,~] = size(MatFileObject,varName);
    if isinf(SDO.zCrop(2)) || (SDO.zCrop(2) > nSamples)
      SDO.zCrop(2) = nSamples;
    end
    doCropData = SDO.loadCroppedData && ~SDO.isCropped && ~isempty(SDO.zRange);
    if doCropData
      byteSizeCorrection = numel(SDO.zRange)./nshots; % get percentage to load
      byteSizeStr = num_to_SI_string(varInfo.bytes*byteSizeCorrection);
      SDO.VPrintF('Loading cropped shot data (%i:%i|%s)...',...
        minmax(SDO.zRange),byteSizeStr);
      SDO.raw = MatFileObject.(varName)(SDO.zRange,:);
      SDO.isCropped = true;
    else
      byteSizeStr = num_to_SI_string(varInfo.bytes);
      SDO.VPrintF('Loading full shot data (%sB)...',byteSizeStr);
      SDO.raw = MatFileObject.(varName);
      SDO.isCropped = false;
      SDO.zCrop = [SDO.zRange(1) SDO.zRange(end)]; % zCrop is full range
    end
    SDO.VPrintF('done (%3.2f s).\n',toc());
  else
    % use data stored in memory
    SDO.PrintF('Using cached data!\n');
  end

  % get required scan info, i.e. dt and prf
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
  SDO.prf = ScanInfo.prf;
  SDO.dt = 1./(ScanInfo.CardProperties.samplingRate*1e6);
  SDO.Filter.df = ScanInfo.CardProperties.samplingRate*1e6;

end
