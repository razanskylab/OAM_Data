% Author: Johannes Rebling
% Date    24. Nov. 2017
% Version 0.1
clj

% proccessed data stored in:
if ispc
  % fullPath = 'C:\Data\mouse_no_1_postprocessed.mat';
  fullPath = 'D:\mouse_no_1_postprocessed.mat';
elseif isunix
  fullPath = '/media/hofmannu/storage/lab_notes_sync/2017_11_13_UH_Segmentation skull brain/mouse1/015_mouse1Radiated_dye_processed.mat';
end

% smart load (using caching) into temp varibale
Temp = load_smart(fullPath);
ExpDataOA = Temp.postprocessed.oa.ExpData;
clear 'temp'

% get raw and enhanced data ----------------------------------------------------
Oa = Maps(ExpDataOA);
Oa.Norm();
Oa.P(); title('In Skull - Raw');
Oa.Apply_CLAHE();
Oa.Apply_CLAHE();
Oa.P(); title('In Skull - Enhanced');

% apply frangi using default stettings -----------------------------------------
Oa.frangiShowScales = true; % show individual frangi scales
% Oa.frangiScaleRange = [2,7];
% Oa.frangiScaleRatio = 1;
Oa.Apply_Frangi();
Oa.P(Oa.filt); title('In Skull - Frangi');

% apply frangi using default stettings on interpolated data --------------------
Oa.Interpolate();
Oa.Apply_Frangi();
Oa.P(Oa.filt); title('In Skull - Frangi on Interp.');


drawnow;
distFig('Pos','C','Screen','Left','Transpose',true);
